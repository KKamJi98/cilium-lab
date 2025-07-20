# vagrant-advanced: 선언적 구성을 이용한 Kubernetes 클러스터

`kubeadm`의 YAML 설정 파일을 사용하여 Kubernetes 클러스터를 자동으로 구성하는 고급 환경입니다. 이 방식은 더 체계적이고 재현 가능성이 높으며, Cilium CNI 사용에 최적화되어 있습니다.

## 주요 특징

- **선언적 클러스터 구성**:
  - `configurations/init-configuration.yaml`: `kubeadm init`에 사용되는 `InitConfiguration` 및 `ClusterConfiguration`이 정의되어 있습니다. 특히, Cilium을 `kube-proxy` 없이 사용하기 위해 `skipPhases: ["kube-proxy"]` 설정이 포함되어 있습니다.
  - `configurations/join-configuration.yaml`: `kubeadm join`에 사용되는 `JoinConfiguration`이 정의되어 있습니다.
- **자동화된 프로비저닝**: `Vagrantfile`은 Master Node 1대와 Worker Node 2대를 생성하고, 아래 스크립트를 사용하여 클러스터를 자동으로 구축합니다.
  - `init_cfg.sh`: 모든 노드에 `containerd`, `kubelet`, `kubeadm`, `kubectl` 등 공통 패키지를 설치하고 초기 설정을 진행합니다.
  - `k8s-ctr.sh`: Master Node에서 `kubeadm init --config=...` 명령을 실행하여 클러스터를 초기화합니다.
  - `k8s-w.sh`: Worker Node에서 `kubeadm join --config=...` 명령을 실행하여 클러스터에 참여합니다.

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
    # kube-proxy가 없는 것을 확인
    kubectl get ds -n kube-system kube-proxy
    ```
