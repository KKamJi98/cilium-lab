#!/usr/bin/env bash
# ==== Cilium Kernel Config Checker ====
#
# Script to check kernel configuration for Cilium.
#
# Status Legend:
#   [OK]   builtin: Kernel built-in
#   [OK]   module loaded: Module is loaded
#   [WARN] module not loaded: Module is not loaded (needs modprobe)
#   [FAIL] absent: Not included in kernel (requires kernel recompile or HWE kernel)

CFG="/boot/config-$(uname -r)"
[[ -f $CFG ]] || { echo "Kernel config file ($CFG) not found"; exit 1; }

# ==== Map kernel config options to module names ====
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

# ==== Required Kernel Options ====
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

# ==== Check Kernel Config ====
echo "Checking Cilium kernel options for kernel $(uname -r)"
for opt in "${OPTS[@]}"; do
  mod=${MODMAP[$opt]:-${opt#CONFIG_}}
  if grep -q "^$opt=y" "$CFG"; then
    printf "  [OK]   %-35s builtin\n" "$opt"
  elif grep -q "^$opt=m" "$CFG"; then
    if lsmod | grep -qw "$mod"; then
      printf "  [OK]   %-35s module loaded\n" "$opt"
    else
      printf "  [WARN] %-35s module not loaded\n" "$opt"
    fi
  else
    printf "  [FAIL] %-35s absent\n" "$opt"
  fi
done