#!/bin/bash

# 재시작할 리소스 타입 목록
RESOURCE_TYPES="deployments statefulsets daemonsets"

echo "=== Kubernetes 클러스터의 모든 네임스페이스에서 리소스 롤아웃 재시작 시작 (순차적) ==="

# 모든 네임스페이스를 가져옵니다.
ALL_NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

# 최종 종료 코드를 추적하기 위한 변수
final_exit_code=0

for NS in $ALL_NAMESPACES; do
  echo "--- 네임스페이스: $NS ---"
  
  for TYPE in $RESOURCE_TYPES; do
    # 해당 네임스페이스의 특정 리소스 타입 이름들을 가져옵니다.
    RESOURCES=$(kubectl get "$TYPE" -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    
    if [ -z "$RESOURCES" ]; then
      # 리소스가 없는 것은 오류가 아니므로 그냥 넘어감
      echo "  $TYPE 리소스가 없습니다."
    else
      for RES in $RESOURCES; do
        echo "  $TYPE/$RES 재시작 중..."
        if kubectl rollout restart "$TYPE/$RES" -n "$NS"; then
          echo "    -> 성공: $TYPE/$RES 재시작 완료."
        else
          echo "    -> 실패: $TYPE/$RES 재시작 중 오류 발생."
          final_exit_code=1 # 실패 시 종료 코드 1로 설정
        fi
      done
    fi
  done
done

echo "==============================================="
if [ "$final_exit_code" -eq 0 ]; then
  echo "=== 모든 대상 리소스의 롤아웃 재시작이 성공적으로 완료되었습니다. ==="
else
  echo "=== 일부 리소스 롤아웃 재시작에 실패했습니다. 로그를 확인해주세요. ==="
fi
echo "==============================================="

exit $final_exit_code
