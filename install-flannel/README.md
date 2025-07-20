# Flannel CNI 설치

이 디렉토리에는 Cilium의 대안으로 Flannel CNI를 설치할 때 사용하는 설정 파일이 있습니다.

## 파일 설명

- **`flannel-values.yaml`**:
  - Flannel Helm 차트를 사용하여 Flannel을 설치할 때 필요한 값을 정의합니다.
  - Pod CIDR을 `10.244.0.0/16`으로 설정합니다.
  - Vagrant 가상 머신의 `eth1` 인터페이스를 사용하도록 지정합니다.

## 사용법

Flannel을 설치하려면 다음 Helm 명령어를 사용할 수 있습니다.

```bash
helm repo add flannel https://flannel-io.github.io/flannel/
helm install flannel flannel/flannel \
  --namespace kube-flannel --create-namespace \
  -f flannel-values.yaml
```