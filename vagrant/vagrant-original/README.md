# vagrant-original: 스크립트 기반 Kubernetes 클러스터

`kubeadm`의 모든 옵션을 명령줄 인자로 직접 전달하는 전통적인 방식을 사용하여 Kubernetes 클러스터를 자동으로 구성하는 환경입니다.

## 주요 특징

- **명령줄 인수 기반 구성**: `vagrant-advanced`와 달리, 별도의 YAML 설정 파일을 사용하지 않고 `kubeadm init` 및 `kubeadm join` 명령어에 모든 필요한 옵션(예: `--pod-network-cidr`)을 직접 명시합니다.
- **자동화된 클러스터 구성**: `Vagrantfile`에 정의된 구성에 따라 Master Node 1대와 Worker Node 2대를 자동으로 생성하고 Kubernetes 클러스터를 구축합니다.
- **스크립트 기반 프로비저닝**:
  - `init_cfg.sh`: 모든 노드(Master, Worker)에 공통적으로 필요한 패키지(kubelet, kubeadm, kubectl, containerd 등)를 설치하고 초기 설정을 진행합니다.
  - `k8s-ctr.sh`: Master Node에서 `kubeadm init` 명령어를 직접 실행하여 Kubernetes 클러스터를 초기화합니다.
  - `k8s-w.sh`: Worker Node에서 `kubeadm join` 명령어를 직접 실행하여 Master Node가 생성한 클러스터에 참여합니다.

## 사용 방법

1.  **Vagrant 및 VirtualBox 설치**: 로컬 환경에 Vagrant와 VirtualBox를 설치합니다.
2.  **Vagrant 실행**: 현재 디렉토리에서 다음 명령어를 실행하여 가상 머신을 생성하고 프로비저닝을 시작합니다.
    ```bash
    vagrant up
    ```
3.  **클러스터 확인**: 프로비저닝이 완료되면 Master Node에 접속하여 클러스터 상태를 확인할 수 있습니다.
    ```bash
    vagrant ssh cilium-m1
    kubectl get nodes
    ```
