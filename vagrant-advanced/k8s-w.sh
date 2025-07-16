#!/usr/bin/env bash

echo ">>>> K8S Node config Start <<<<"

echo "[TASK 1] K8S Controlplane Join"
# Vagrantfile에서 전달받은 IP 주소($1)를 노드 IP로 사용하여 join을 실행함.
kubeadm join --config /vagrant/configurations/join-configuration.yaml --node-ip=$1


echo ">>>> K8S Node config End <<<<"
