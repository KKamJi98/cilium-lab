# Helm 차트 값 파일

이 디렉토리에는 `helm install` 또는 `helm upgrade` 명령어로 Cilium 및 관련 구성 요소를 설치할 때 사용하는 `values.yaml` 파일들이 저장되어 있습니다.

## 디렉토리 구조

- **`cilium/`**: Cilium CNI 설치를 위한 `values.yaml` 파일들이 있습니다.
- **`monitoring/`**: 현재는 비어 있으며, 향후 Prometheus, Grafana 등 모니터링 관련 Helm 차트의 값을 저장하기 위한 공간입니다.