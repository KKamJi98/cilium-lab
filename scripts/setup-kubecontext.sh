#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

KUBE_DIR="$HOME/.kube"
CILIUM_CONF="$KUBE_DIR/cilium-config"
MAIN_CONF="$KUBE_DIR/config"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# 1. 원격 admin.conf 파일 가져오기
ssh cilium-m1 "sudo cat /etc/kubernetes/admin.conf" > "${CILIUM_CONF}"

# 2. API 서버 주소, 클러스터 이름, 사용자 이름, 컨텍스트 이름 변경 (yq 사용)
yq e '.clusters[0].cluster.server = "https://192.168.0.2:56444"'    -i "${CILIUM_CONF}"
yq e '.clusters[0].name = "cilium-cluster"'                        -i "${CILIUM_CONF}"
yq e '.users[0].name = "cilium-user"'                              -i "${CILIUM_CONF}"
yq e '.contexts[0].name = "cilium"'                                -i "${CILIUM_CONF}"
yq e '.contexts[0].context.cluster = "cilium-cluster"'            -i "${CILIUM_CONF}"
yq e '.contexts[0].context.user = "cilium-user"'                   -i "${CILIUM_CONF}"
# 2-1. 기본 컨텍스트 설정
yq e '.current-context = "cilium"'                                 -i "${CILIUM_CONF}"

# 3. 기존 kubeconfig 백업
mkdir -p "${KUBE_DIR}"
cp "${MAIN_CONF}" "${KUBE_DIR}/config.bak_${TIMESTAMP}"

# 4. 새로운 config 병합 (cilium-config 우선)
KUBECONFIG="${CILIUM_CONF}:${MAIN_CONF}" \
  kubectl config view --flatten --merge > "${KUBE_DIR}/config.merged"

# 5. 병합 결과를 공식 config로 교체
mv "${KUBE_DIR}/config.merged" "${MAIN_CONF}"

# 6. 권한 설정
chmod 600 "${MAIN_CONF}"

echo "✅ kubeconfig 병합 완료!"
echo "  주 config: ${MAIN_CONF}"
echo "  백업 파일: ${KUBE_DIR}/config.bak_${TIMESTAMP}"
