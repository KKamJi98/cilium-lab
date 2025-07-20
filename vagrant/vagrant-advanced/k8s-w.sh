#!/usr/bin/env bash

# === Arguments from Vagrantfile ===
# $1: NODE_IP (e.g., 192.168.10.101)

NODE_IP="$1"

echo ">>>> K8S Node config Start <<<<"

echo "[TASK 0] Setting Node IP"
sed -i "s/__NODE_IP__/$NODE_IP/g" /tmp/configurations/join-configuration.yaml

echo "[TASK 1] K8S Controlplane Join"
kubeadm join --config /tmp/configurations/join-configuration.yaml


echo ">>>> K8S Node config End <<<<"
