# Cilium-Lab

Vagrant와 VirtualBox를 사용하여 Kubernetes 클러스터를 구축하고 Cilium을 테스트하기 위한 실습 환경입니다.

## 프로젝트 구조

```
.
├── helm/                  # Cilium, Flannel 등 Helm 차트 값 파일
│   ├── cilium/
│   └── monitoring/
├── install-flannel/       # Flannel CNI 설치 관련 파일
├── scripts/               # 클러스터 구성 및 관리를 위한 헬퍼 스크립트
└── vagrant/               # Vagrant를 이용한 Kubernetes 클러스터 구성 환경
    ├── vagrant-advanced/  # Kubeadm YAML 설정을 사용한 고급 구성
    └── vagrant-original/  # Kubeadm 명령줄 인자를 사용한 기본 구성
```

## 디렉토리 상세 설명

### `vagrant`

두 가지 버전의 Kubernetes 클러스터 구성 환경을 제공합니다.

- **`vagrant-original/`**: `kubeadm`의 모든 옵션을 명령줄 인자로 전달하는 전통적인 방식을 사용하여 Kubernetes 클러스터를 구성합니다.
- **`vagrant-advanced/`**: `kubeadm`의 `InitConfiguration`, `JoinConfiguration` 등 YAML 설정 파일을 사용하여 좀 더 선언적이고 체계적인 방식으로 Kubernetes 클러스터를 구성합니다. (Cilium 설치 시 `kube-proxy` 제외 구성 포함)

각 디렉토리의 `Vagrantfile`을 통해 Master Node 1대, Worker Node 2대의 가상머신을 생성하고 클러스터를 구축합니다.

### `helm`

Cilium 및 모니터링 관련 Helm 차트의 `values.yaml` 파일들을 관리합니다.

- **`helm/cilium/`**: Cilium 설치 시 사용하는 `values.yaml` 파일이 있습니다.
  - `cilium-values-lab.yaml`: 실습 환경에 최적화된 기본 값 파일입니다. (`k8sServiceHost` 고정)
  - `cilium-values-kkamji.yaml`: `k8sServiceHost`를 자동으로 탐지하는 등 좀 더 유연한 설정입니다.
- **`helm/monitoring/`**: 향후 모니터링 도구(Prometheus, Grafana 등)를 위한 설정 파일을 위치시킬 공간입니다.

### `install-flannel`

Cilium 대신 Flannel CNI를 설치할 경우 사용하는 `flannel-values.yaml` 파일이 있습니다.

### `scripts`

클러스터 설치 및 운영을 돕는 다양한 유틸리티 스크립트가 있습니다.

- `check-cilium-kernel-cfg.sh`: Cilium 실행에 필요한 커널 옵션이 활성화되어 있는지 확인합니다.
- `setup_cilium_kernel.sh`: 필요한 커널 모듈을 확인하고, 비활성화된 경우 자동으로 로드합니다.
- `rollout-restart-all.sh`: 클러스터 내 모든 주요 워크로드(Deployment, StatefulSet, DaemonSet)를 재시작합니다.
- `setup-kubecontext.sh`: 로컬 머신에서 `kubectl`을 사용하여 원격 클러스터를 제어할 수 있도록 `~/.kube/config` 파일을 자동으로 설정합니다.

## 시작하기

1.  **Vagrant 및 VirtualBox 설치**: 로컬 환경에 Vagrant와 VirtualBox를 설치합니다.
2.  **Vagrant 환경 선택**: `vagrant-original` 또는 `vagrant-advanced` 디렉토리로 이동합니다.
3.  **Vagrant 실행**: 다음 명령어를 실행하여 가상 머신을 생성하고 Kubernetes 클러스터 구축을 시작합니다.
    ```bash
    vagrant up
    ```
4.  **클러스터 확인**: 프로비저닝이 완료되면 Master Node에 접속하여 클러스터 상태를 확인할 수 있습니다.
    ```bash
    vagrant ssh cilium-m1
    kubectl get nodes
    ```
5.  **로컬에서 `kubectl` 사용 (선택 사항)**: `scripts/setup-kubecontext.sh` 스크립트를 실행하여 로컬에서 클러스터를 제어할 수 있습니다.

## CNI 설치

- **Cilium**: `vagrant-advanced` 환경에서는 `kube-proxy`가 비활성화된 상태로 클러스터가 구성되므로, Cilium을 설치하는 것이 권장됩니다. `helm/cilium`의 `values.yaml` 파일을 사용하여 설치를 진행할 수 있습니다.
- **Flannel**: `install-flannel` 디렉토리의 설정 파일을 사용하여 Flannel을 설치할 수 있습니다.