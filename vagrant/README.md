# Vagrant 기반 Kubernetes 클러스터

이 디렉토리에는 Vagrant와 VirtualBox를 사용하여 Kubernetes 클러스터를 자동으로 구축하기 위한 두 가지 다른 접근 방식의 환경이 포함되어 있습니다.

## 환경 구성

- **`vagrant-original/`**:
  - `kubeadm` 명령어에 모든 옵션을 직접 인자로 전달하는 전통적인 방식을 사용하여 클러스터를 구성합니다.
  - Kubernetes 클러스터 구축의 기본적인 스크립트 기반 흐름을 이해하는 데 유용합니다.

- **`vagrant-advanced/`**:
  - `kubeadm`의 `InitConfiguration`, `JoinConfiguration`과 같은 YAML 설정 파일을 사용하여 클러스터를 구성하는 선언적인 방식입니다.
  - Cilium CNI 사용에 최적화되어 있으며, `kube-proxy`를 비활성화하는 설정이 기본적으로 포함되어 있습니다.

각 디렉토리의 `README.md` 파일에서 더 자세한 내용을 확인할 수 있습니다.