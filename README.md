# Cilium-Lab

Vagrant와 VirtualBox를 사용하여 Kubernetes 클러스터를 구축하고 Cilium을 테스트하기 위한 실습 환경입니다.

## 디렉토리 구조

이 프로젝트는 두 가지 버전의 Kubernetes 클러스터 구성 환경을 제공합니다.

- **`vagrant-original/`**: `kubeadm`의 모든 옵션을 명령줄 인자로 전달하는 전통적인 방식을 사용하여 Kubernetes 클러스터를 구성합니다.
- **`vagrant-advanced/`**: `kubeadm`의 `InitConfiguration`, `JoinConfiguration` 등 YAML 설정 파일을 사용하여 좀 더 선언적이고 체계적인 방식으로 Kubernetes 클러스터를 구성합니다.

## 목적

- 다양한 방식의 Kubernetes 클러스터 구축 방법을 학습합니다.
- 구성된 Kubernetes 클러스터 환경에서 Cilium CNI(Container Network Interface)를 설치하고 기능을 테스트합니다.

## 시작하기

각 디렉토리의 `README.md` 파일을 참고하여 원하는 버전의 Kubernetes 클러스터를 구축할 수 있습니다.

- [vagrant-original/README.md](./vagrant-original/README.md)
- [vagrant-advanced/README.md](./vagrant-advanced/README.md)
