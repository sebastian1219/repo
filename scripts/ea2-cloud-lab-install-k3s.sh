#!/usr/bin/env bash
# Uso local o desde CI:
#   ea2-cloud-lab-install-k3s.sh <pem> <server_public_ip> <server_private_ip> <agent_public_ip> <nlb_dns>
set -euo pipefail

PEM=${1:?pem}
SERVER_PUB=${2:?server public}
SERVER_PRV=${3:?server private}
AGENT_PUB=${4:?agent public}
NLB_DNS=${5:-$SERVER_PUB}

SSH_OPTS=( -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$PEM" )

ssh "${SSH_OPTS[@]}" "ubuntu@${SERVER_PUB}" \
  "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --write-kubeconfig-mode 644 --advertise-address ${SERVER_PRV} --node-external-ip ${SERVER_PUB} --tls-san ${SERVER_PUB} --tls-san ${NLB_DNS}' sh -"

TOKEN=$(ssh "${SSH_OPTS[@]}" "ubuntu@${SERVER_PUB}" sudo cat /var/lib/rancher/k3s/server/node-token)

ssh "${SSH_OPTS[@]}" "ubuntu@${AGENT_PUB}" \
  "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='agent --server https://${SERVER_PRV}:6443 --token ${TOKEN} --node-external-ip ${AGENT_PUB}' sh -"

for _ in $(seq 1 36); do
  if ssh "${SSH_OPTS[@]}" "ubuntu@${SERVER_PUB}" sudo kubectl get nodes 2>/dev/null | grep -q Ready; then
    exit 0
  fi
  sleep 5
done
echo "timeout esperando nodos Ready"
exit 1
