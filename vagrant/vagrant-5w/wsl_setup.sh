# cilium_bootstrap.sh
#!/usr/bin/env bash
set -euo pipefail

# 기본 옵션
HOSTNAME_TARGET="192.168.0.2"                # 192.168.0.2로 쓰려면 --host-ip 192.168.0.2
ADMIN_HOST="cilium-ctr"                    # admin.conf 가져올 대상. 필요시 --admin-host
API_SERVER="https://192.168.0.2:56444"     # 필요시 --api로 변경

# 경로
SSH_DIR="${HOME}/.ssh"
CONF_DIR="${SSH_DIR}/config.d"
CONFIG="${CONF_DIR}/cilium-lab"
KEY_DIR="${SSH_DIR}/vagrant-keys"
KUBE_DIR="${HOME}/.kube"
CILIUM_CONF="${KUBE_DIR}/cilium-config"
MAIN_CONF="${KUBE_DIR}/config"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# 인자 파싱
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host-ip)    HOSTNAME_TARGET="$2"; shift 2;;
    --admin-host) ADMIN_HOST="$2"; shift 2;;
    --api)        API_SERVER="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

# 전제 체크
command -v sed >/dev/null      || { echo "sed not found"; exit 1; }
command -v awk >/dev/null      || { echo "awk not found"; exit 1; }
command -v yq >/dev/null       || { echo "yq not found"; exit 1; }
command -v kubectl >/dev/null  || { echo "kubectl not found"; exit 1; }
if ! command -v vagrant.exe >/dev/null 2>&1; then
  export PATH="$PATH:/mnt/c/Program Files/HashiCorp/Vagrant/bin"
fi
command -v vagrant.exe >/dev/null || { echo "vagrant.exe not found in PATH"; exit 1; }

# VAGRANT_HOME 자동 추론
if [[ -z "${VAGRANT_HOME:-}" ]]; then
  if command -v powershell.exe >/dev/null 2>&1; then
    USERPROFILE_WIN="$(powershell.exe -NoProfile -Command '$env:USERPROFILE' | tr -d '\r')"
    if command -v wslpath >/dev/null 2>&1; then
      USERPROFILE_UNIX="$(wslpath -u "${USERPROFILE_WIN}")"
      export VAGRANT_HOME="${USERPROFILE_UNIX}/.vagrant.d"
    else
      export VAGRANT_HOME="/mnt/c/Users/$(basename "${USERPROFILE_WIN}")/.vagrant.d"
    fi
  else
    export VAGRANT_HOME="/mnt/c/Users/${USER}/.vagrant.d"
  fi
fi

: "${VAGRANT_WSL_ENABLE_WINDOWS_ACCESS:=1}"
: "${VAGRANT_PREFER_SYSTEM_SSH:=true}"
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS VAGRANT_PREFER_SYSTEM_SSH

# 디렉터리
mkdir -p "${CONF_DIR}" "${KEY_DIR}" "${KUBE_DIR}"
chmod 700 "${SSH_DIR}" 2>/dev/null || true
chmod 700 "${KEY_DIR}"

# ~/.ssh/config Include
if ! { [[ -f "${SSH_DIR}/config" ]] && grep -q '^Include ~/.ssh/config.d/\*' "${SSH_DIR}/config"; }; then
  { echo 'Include ~/.ssh/config.d/*'; echo; [[ -f "${SSH_DIR}/config" ]] && cat "${SSH_DIR}/config"; } > "${SSH_DIR}/config.new"
  mv "${SSH_DIR}/config.new" "${SSH_DIR}/config"
fi

# 1) vagrant ssh-config 생성 및 변환
vagrant.exe ssh-config \
| sed -E \
    -e 's/\r$//' \
    -e 's/^Host k8s-/Host cilium-/' \
    -e 's/^Host router$/Host cilium-router/' \
    -e 's#IdentityFile C:/#IdentityFile /mnt/c/#' \
    -e "s/^([[:space:]]*)HostName[[:space:]]+127\.0\.0\.1/\\1HostName ${HOSTNAME_TARGET}/" \
> "${CONFIG}"
chmod 600 "${CONFIG}"

# 2) 각 Host의 private_key를 홈으로 복사하고 IdentityFile 갱신
mapfile -t HOSTS < <(awk '/^Host[[:space:]]+/ {print $2}' "${CONFIG}")
for H in "${HOSTS[@]}"; do
  KEY_SRC="$(awk -v h="${H}" '
    BEGIN{inblk=0}
    $1=="Host"{ if(inblk) exit; inblk=($2==h) }
    inblk && $1=="IdentityFile"{print $2; exit}
  ' "${CONFIG}")"
  [[ -z "${KEY_SRC}" ]] && { echo "스킵: ${H} IdentityFile 없음"; continue; }

  KEY_DST="${KEY_DIR}/${H}.key"
  cp "${KEY_SRC}" "${KEY_DST}"
  chmod 600 "${KEY_DST}"

  awk -v h="${H}" -v newkey="${KEY_DST}" '
    BEGIN{inblk=0}
    {
      if($1=="Host"){ if(inblk){inblk=0} if($2==h){inblk=1} print; next }
      if(inblk && $1=="IdentityFile"){ sub($2, newkey); print; next }
      print
    }
  ' "${CONFIG}" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "${CONFIG}"

  echo "Key OK: ${H} → ${KEY_DST}"
done
chmod 600 "${CONFIG}"

# 3) SSH 테스트
ssh -F "${CONFIG}" -o ConnectTimeout=5 "${ADMIN_HOST}" 'true' && echo "SSH OK: ${ADMIN_HOST}"

# 3-1) API_SERVER 호스트 추출
# IPv6/IPv4/호스트네임 모두 처리
API_HOST="$(printf '%s\n' "${API_SERVER}" \
  | sed -E 's#^https?://\[([^]]+)\](:[0-9]+)?/?.*#\1#;t; s#^https?://([^/:]+)(:[0-9]+)?/?.*#\1#')"

# 3-2) SAN 강제 추가: 기존 SAN + 새 항목으로 재발급
echo "[INFO] Force-regenerate apiserver cert with merged SANs"
ssh -F "${CONFIG}" "${ADMIN_HOST}" "bash -s" -- "${API_HOST}" <<'EOSH'
set -euo pipefail
API_HOST_IN="$1"
cd /etc/kubernetes/pki

# 기준이 될 crt 선택
CRT_SRC="/etc/kubernetes/pki/apiserver.crt"
if [ ! -f "$CRT_SRC" ] && [ -f "/etc/kubernetes/pki/apiserver.crt.bak" ]; then
  CRT_SRC="/etc/kubernetes/pki/apiserver.crt.bak"
fi

EXISTING_SAN=""
if [ -f "$CRT_SRC" ]; then
  EXISTING_SAN=$(sudo openssl x509 -in "$CRT_SRC" -noout -text \
    | awk '/Subject Alternative Name/{getline; print}')
fi

# SAN 정규화
CLEAN=$(printf '%s\n' "$EXISTING_SAN" \
  | sed -E 's/^[[:space:]]*//; s/,/ /g; s/DNS:[[:space:]]*//g; s/IP Address:[[:space:]]*//g')

# 기본 SAN과 노드 IP 추가
DEFAULTS="kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local 10.96.0.1"
NODEIP="192.168.10.100"

ALL=$(printf '%s %s %s %s\n' "$CLEAN" "$DEFAULTS" "$NODEIP" "$API_HOST_IN" \
  | tr ' ' '\n' | awk 'NF' | awk '!x[$0]++' | paste -sd, -)

echo "[INFO] SAN final = ${ALL}"

# 백업
sudo mv /etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.crt.bak2 2>/dev/null || true
sudo mv /etc/kubernetes/pki/apiserver.key /etc/kubernetes/pki/apiserver.key.bak2 2>/dev/null || true

# 재발급
sudo kubeadm init phase certs apiserver --apiserver-cert-extra-sans "${ALL}"
sudo systemctl restart kubelet

# 확인
for i in {1..30}; do
  if sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text \
     | grep -qE "(DNS|IP Address):[[:space:]]*192\.168\.0\.2|,[[:space:]]192\.168\.0\.2"; then
    echo "[INFO] SAN updated and includes 192.168.0.2"
    break
  fi
  sleep 1
done
EOSH

# 인자 전달
# shellcheck disable=SC2029
ssh -F "${CONFIG}" "${ADMIN_HOST}" "true" >/dev/null 2>&1  # noop to ensure connection ok

# 4) kubeconfig 병합
ssh -F "${CONFIG}" "${ADMIN_HOST}" "sudo cat /etc/kubernetes/admin.conf" > "${CILIUM_CONF}"

yq e ".clusters[0].cluster.server = \"${API_SERVER}\""     -i "${CILIUM_CONF}"
yq e ".clusters[0].name = \"cilium-cluster\""              -i "${CILIUM_CONF}"
yq e ".users[0].name = \"cilium-user\""                    -i "${CILIUM_CONF}"
yq e ".contexts[0].name = \"cilium\""                      -i "${CILIUM_CONF}"
yq e ".contexts[0].context.cluster = \"cilium-cluster\""   -i "${CILIUM_CONF}"
yq e ".contexts[0].context.user = \"cilium-user\""         -i "${CILIUM_CONF}"
yq e '.current-context = "cilium"'                         -i "${CILIUM_CONF}"

[[ -f "${MAIN_CONF}" ]] || touch "${MAIN_CONF}"
cp "${MAIN_CONF}" "${KUBE_DIR}/config.bak_${TIMESTAMP}"

KUBECONFIG="${CILIUM_CONF}:${MAIN_CONF}" \
  kubectl config view --flatten --merge > "${KUBE_DIR}/config.merged"

mv "${KUBE_DIR}/config.merged" "${MAIN_CONF}"
chmod 600 "${MAIN_CONF}"

echo "완료"
echo "  SSH config: ${CONFIG}"
echo "  Kubeconfig: ${MAIN_CONF}"
echo "  Backup    : ${KUBE_DIR}/config.bak_${TIMESTAMP}"
