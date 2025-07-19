#!/usr/bin/env bash
# ==== Cilium Kernel Setup Script ====
#
# Checks for required kernel options for Cilium and offers to load
# any missing modules automatically.
#
# Status Legend:
#   [OK]   builtin: Kernel built-in
#   [OK]   module loaded: Module is loaded
#   [WARN] module not loaded: Module is not loaded (can be loaded with modprobe)
#   [FAIL] absent: Not included in kernel (requires kernel recompile or HWE kernel)

# ==== Check for root privileges ====
if (( EUID != 0 )); then
  SUDO="sudo"
  echo "(This script will attempt to load kernel modules using sudo)"
else
  SUDO=""
fi

# ==== Kernel Config File ====
CFG="/boot/config-$(uname -r)"
[[ -f $CFG ]] || { echo "Kernel config file ($CFG) not found." >&2; exit 1; }

# ==== Module Name Mapping ====
declare -A MODMAP=(
  # ==== eBPF ====
  [CONFIG_NET_CLS_BPF]=cls_bpf
  [CONFIG_NET_SCH_INGRESS]=sch_ingress
  [CONFIG_CRYPTO_USER_API_HASH]=algif_hash

  # ==== Iptables-based Masquerading ====
  [CONFIG_NETFILTER_XT_SET]=xt_set
  [CONFIG_IP_SET]=ip_set
  [CONFIG_IP_SET_HASH_IP]=ip_set_hash_ip
  [CONFIG_NETFILTER_XT_MATCH_COMMENT]=xt_comment
  [CONFIG_NETFILTER_XT_TARGET_TPROXY]=xt_TPROXY
  [CONFIG_NETFILTER_XT_TARGET_MARK]=xt_mark
  [CONFIG_NETFILTER_XT_TARGET_CT]=xt_CT
  [CONFIG_NETFILTER_XT_MATCH_MARK]=xt_mark
  [CONFIG_NETFILTER_XT_MATCH_SOCKET]=xt_socket

  # ==== Tunneling and Routing ====
  [CONFIG_VXLAN]=vxlan
  [CONFIG_GENEVE]=geneve

  # ==== Bandwidth Manager ====
  [CONFIG_NET_SCH_FQ]=sch_fq

  # ==== Netkit Device Mode ====
  [CONFIG_NETKIT]=netkit

  # ==== IPsec ====
  [CONFIG_XFRM_ALGO]=xfrm_algo
  [CONFIG_XFRM_USER]=xfrm_user
  [CONFIG_INET_ESP]=esp4
  [CONFIG_INET6_ESP]=esp6
  [CONFIG_INET_IPCOMP]=ipcomp
  [CONFIG_INET6_IPCOMP]=ipcomp6
  [CONFIG_INET_XFRM_TUNNEL]=xfrm4_tunnel
  [CONFIG_INET6_XFRM_TUNNEL]=xfrm6_tunnel
  [CONFIG_INET_TUNNEL]=tunnel4
  [CONFIG_INET6_TUNNEL]=tunnel6
)

# ==== Kernel Options to Check ====
OPTS=(
  # ==== eBPF ====
  CONFIG_BPF CONFIG_BPF_SYSCALL CONFIG_NET_CLS_BPF CONFIG_BPF_JIT
  CONFIG_NET_CLS_ACT CONFIG_NET_SCH_INGRESS CONFIG_CRYPTO_SHA1
  CONFIG_CRYPTO_USER_API_HASH CONFIG_CGROUPS CONFIG_CGROUP_BPF
  CONFIG_PERF_EVENTS CONFIG_SCHEDSTATS

  # ==== Iptables-based Masquerading ====
  CONFIG_NETFILTER_XT_SET CONFIG_IP_SET CONFIG_IP_SET_HASH_IP
  CONFIG_NETFILTER_XT_MATCH_COMMENT

  # ==== Tunneling and Routing ====
  CONFIG_VXLAN CONFIG_GENEVE CONFIG_FIB_RULES

  # ==== L7 and FQDN Policies ====
  CONFIG_NETFILTER_XT_TARGET_TPROXY CONFIG_NETFILTER_XT_TARGET_MARK
  CONFIG_NETFILTER_XT_TARGET_CT CONFIG_NETFILTER_XT_MATCH_MARK
  CONFIG_NETFILTER_XT_MATCH_SOCKET

  # ==== IPsec ====
  CONFIG_XFRM CONFIG_XFRM_OFFLOAD CONFIG_XFRM_STATISTICS
  CONFIG_XFRM_ALGO CONFIG_XFRM_USER CONFIG_INET_ESP CONFIG_INET6_ESP
  CONFIG_INET_IPCOMP CONFIG_INET6_IPCOMP CONFIG_INET_XFRM_TUNNEL
  CONFIG_INET6_XFRM_TUNNEL CONFIG_INET_TUNNEL CONFIG_INET6_TUNNEL
  CONFIG_INET_XFRM_MODE_TUNNEL CONFIG_CRYPTO_AEAD CONFIG_CRYPTO_AEAD2
  CONFIG_CRYPTO_GCM CONFIG_CRYPTO_SEQIV CONFIG_CRYPTO_CBC
  CONFIG_CRYPTO_HMAC CONFIG_CRYPTO_SHA256 CONFIG_CRYPTO_AES

  # ==== Bandwidth Manager ====
  CONFIG_NET_SCH_FQ

  # ==== Netkit Device Mode ====
  CONFIG_NETKIT
)

# ==== Initial Check Loop ====
declare -a WARN_OPTS=()
declare -a FAIL_OPTS=()
declare -A MOD_NAMES=()

echo "Checking Cilium kernel options for kernel $(uname -r)"
echo "=================================================="

for opt in "${OPTS[@]}"; do
  mod=${MODMAP[$opt]:-${opt#CONFIG_}}
  MOD_NAMES[$opt]=$mod

  if grep -q "^$opt=y" "$CFG"; then
    printf "  [OK]   %-35s builtin\n" "$opt"
  elif grep -q "^$opt=m" "$CFG"; then
    if lsmod | grep -qw "$mod"; then
      printf "  [OK]   %-35s module loaded\n" "$opt"
    else
      printf "  [WARN] %-35s module not loaded (module: %s)\n" "$opt" "$mod"
      WARN_OPTS+=("$opt")
    fi
  else
    printf "  [FAIL] %-35s absent\n" "$opt"
    FAIL_OPTS+=("$opt")
  fi
done

# ==== Summary and Action ====
echo "=================================================="
echo -e "\nCheck Summary and Action"
echo "--------------------------------------------------"

if (( ${#WARN_OPTS[@]} == 0 && ${#FAIL_OPTS[@]} == 0 )); then
  echo "All required kernel options are enabled."
  exit 0
fi

if (( ${#FAIL_OPTS[@]} > 0 )); then
  echo "[FAIL] Required options not enabled:"
  for opt in "${FAIL_OPTS[@]}"; do
    printf "  - %-35s : Kernel recompile or HWE kernel installation required\n" "$opt"
  done
  echo ""
fi

if (( ${#WARN_OPTS[@]} > 0 )); then
  echo "[WARN] The following modules are not loaded:"
  for opt in "${WARN_OPTS[@]}"; do
    printf "  - %-35s (module: %s)\n" "$opt" "${MOD_NAMES[$opt]}"
  done
  echo ""

  read -rp "Load all the above modules with modprobe? (y/N) " answer
  if [[ ${answer,,} == y ]]; then
    echo "--------------------------------------------------"
    echo "Loading modules..."
    for opt in "${WARN_OPTS[@]}"; do
      mod_to_load=${MOD_NAMES[$opt]}
      printf "  - Loading %-15s... " "$mod_to_load"
      if $SUDO modprobe "$mod_to_load" 2>/dev/null; then
        printf "[SUCCESS]\n"
      else
        printf "[FAIL] (Could not load module. File not found?)\n"
      fi
    done
    echo "--------------------------------------------------"
    echo "Module loading finished. Run the script again to verify."
  fi
fi