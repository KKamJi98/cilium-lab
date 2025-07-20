# 유틸리티 스크립트

이 디렉토리에는 Kubernetes 클러스터의 설치, 구성 및 관리를 자동화하고 돕는 헬퍼 스크립트들이 포함되어 있습니다.

## 스크립트 목록

- **`check-cilium-kernel-cfg.sh`**:
  - 현재 시스템의 커널 설정을 확인하여 Cilium 실행에 필요한 모든 옵션이 활성화되어 있는지 검사하고 결과를 출력합니다.

- **`setup_cilium_kernel.sh`**:
  - `check-cilium-kernel-cfg.sh`의 확장된 버전입니다.
  - 필요한 커널 옵션을 확인하고, 모듈로 제공되지만 로드되지 않은 옵션이 있을 경우 `modprobe`를 사용하여 자동으로 로드할지 사용자에게 묻습니다.

- **`rollout-restart-all.sh`**:
  - 클러스터의 모든 네임스페이스를 순회하며 `deployments`, `statefulsets`, `daemonsets` 리소스의 롤아웃 재시작을 수행합니다.
  - 구성 변경을 전체적으로 적용하거나 모든 Pod를 강제로 새로 고쳐야 할 때 유용합니다.

- **`setup-kubecontext.sh`**:
  - Vagrant로 생성된 `cilium-m1` 마스터 노드에서 `admin.conf` 파일을 가져옵니다.
  - 가져온 설정을 로컬 머신의 `~/.kube/config` 파일에 병합하여, 로컬 `kubectl` 명령어로 원격 클러스터를 즉시 제어할 수 있도록 설정합니다.