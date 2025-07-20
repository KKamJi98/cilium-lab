# Cilium Helm Values

이 디렉토리에는 Cilium을 설치하기 위한 다양한 `values.yaml` 설정 파일이 포함되어 있습니다.

## 파일 설명

- **`cilium-values-lab.yaml`**:
  - 실습 환경을 위해 사전 구성된 `values.yaml` 파일입니다.
  - Kubernetes API 서버의 주소 (`k8sServiceHost`)가 `192.168.10.100`으로 고정되어 있습니다.
  - `vagrant-advanced` 또는 `vagrant-original` 환경에서 `Vagrantfile`에 정의된 IP 주소와 일치합니다.

- **`cilium-values-kkamji.yaml`**:
  - `k8sServiceHost` 옵션을 `auto`로 설정하여, Cilium이 Kubernetes API 서버 주소를 자동으로 찾도록 하는 좀 더 유연한 구성입니다.
  - 대부분의 설정은 `cilium-values-lab.yaml`과 동일합니다.

두 파일 모두 Hubble, Prometheus 메트릭, 네이티브 라우팅, `kube-proxy` 대체 등의 고급 기능을 활성화하도록 설정되어 있습니다.