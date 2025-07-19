#!/bin/bash

# 재시작할 리소스 타입 목록
RESOURCE_TYPES="deployments statefulsets daemonsets"

echo "=== Kubernetes 클러스터의 모든 네임스페이스에서 리소스 롤아웃 재시작 시작 ==="

# 모든 네임스페이스를 가져옵니다.
NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

for NS in $NAMESPACES; do
  echo "--- 네임스페이스: $NS ---"
  
  for TYPE in $RESOURCE_TYPES; do
    echo "  >> 리소스 타입: $TYPE 재시작 중..."
    
    # 해당 네임스페이스의 특정 리소스 타입 이름들을 가져옵니다.
    RESOURCES=$(kubectl get "$TYPE" -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    
    if [ -z "$RESOURCES" ]; then
      echo "    이 네임스페이스($NS)에는 $TYPE 리소스가 없습니다."
    else
      for RES in $RESOURCES; do
        echo "    $TYPE/$RES 재시작 중..."
        kubectl rollout restart "$TYPE/$RES" -n "$NS"
        if [ $? -eq 0 ]; then
          echo "    $TYPE/$RES 재시작 성공."
        else
          echo "    $TYPE/$RES 재시작 실패 또는 오류 발생."
        fi
      done
    fi
  done
done

echo "=== 모든 리소스 롤아웃 재시작 완료 ==="