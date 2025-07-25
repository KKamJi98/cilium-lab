#!/usr/bin/env bash

# === Arguments from Vagrantfile ===
# $1: NODE_IP (e.g., 192.168.10.100)
# $2: WORKER_COUNT (e.g., 2)
# $3: CILIUM_VERSION (e.g., 1.17.6)
# $4: K8S_APT_VERSION (e.g., 1.33.2-1.1)

NODE_IP="$1"
WORKER_COUNT="$2"
CILIUM_VERSION="$3"
K8S_APT_VERSION="$4"

# Extract the semantic version (e.g., 1.33.2) for kubeadm config
K8S_SEMVER=$(echo "$K8S_APT_VERSION" | cut -d'-' -f1)

echo ">>>> K8S Controlplane config Start <<<<"

echo "[TASK 0] Setting Node IP"
sed -i "s/__NODE_IP__/$NODE_IP/g" /tmp/configurations/init-configuration.yaml
sed -i "s/__KUBERNETES_VERSION__/v$K8S_SEMVER/g" /tmp/configurations/init-configuration.yaml

echo "[TASK 1] Initial Kubernetes"
kubeadm init --config /tmp/configurations/init-configuration.yaml > /dev/null 2>&1


echo "[TASK 2] Setting kube config file"
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config


echo "[TASK 3] Source the completion"
echo 'source <(kubectl completion bash)' >> /etc/profile
echo 'source <(kubeadm completion bash)' >> /etc/profile


echo "[TASK 4] Alias kubectl to k"
echo 'alias k=kubectl' >> /etc/profile
echo 'alias kc=kubecolor' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile


echo "[TASK 5] Install Kubectx & Kubens"
git clone https://github.com/ahmetb/kubectx /opt/kubectx >/dev/null 2>&1
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx


echo "[TASK 6] Install Kubeps & Setting PS1"
git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1 >/dev/null 2>&1
cat <<"EOT" >> /root/.bash_profile
source /root/kube-ps1/kube-ps1.sh
KUBE_PS1_SYMBOL_ENABLE=true
function get_cluster_short() {
  echo "$NODE_IP" | cut -d . -f1
}
KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
KUBE_PS1_SUFFIX=') '
PS1='$(kube_ps1)'$PS1
EOT
kubectl config rename-context "kubernetes-admin@kubernetes" "HomeLab" >/dev/null 2>&1

echo "[TASK 7] Install Cilium CNI"
NODEIP=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1
helm repo update >/dev/null 2>&1
helm install cilium cilium/cilium --version $CILIUM_VERSION --namespace kube-system \
--set k8sServiceHost=192.168.10.100 --set k8sServicePort=6443 \
--set ipam.mode="cluster-pool" --set ipam.operator.clusterPoolIPv4PodCIDRList={"172.20.0.0/16"} --set ipv4NativeRoutingCIDR=172.20.0.0/16 \
--set routingMode=native --set autoDirectNodeRoutes=true --set endpointRoutes.enabled=true \
--set kubeProxyReplacement=true --set bpf.masquerade=true --set installNoConntrackIptablesRules=true \
--set endpointHealthChecking.enabled=false --set healthChecking=false \
--set hubble.enabled=false --set operator.replicas=1 --set debug.enabled=true >/dev/null 2>&1


echo "[TASK 8] Install Cilium CLI"
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz >/dev/null 2>&1
tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz


echo "[TASK 9] Install Kubeps & Setting PS1"
echo "192.168.10.100 cilium-m1" >> /etc/hosts
for (( i=1; i<=$WORKER_COUNT; i++  )); do echo "192.168.10.10$i cilium-w$i" >> /etc/hosts; done


echo ">>>> K8S Controlplane Config End <<<<"