#!/usr/bin/env bash

echo ">>>> K8S Node config Start <<<<"

echo "[TASK 0] Setting Node IP"
sed -i "s/__NODE_IP__/$1/g" /opt/configurations/join-configuration.yaml

echo "[TASK 1] K8S Controlplane Join"
kubeadm join --config /opt/configurations/join-configuration.yaml


echo ">>>> K8S Node config End <<<<"