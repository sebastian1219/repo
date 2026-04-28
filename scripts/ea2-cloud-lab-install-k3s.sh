#!/usr/bin/env bash
# Uso local o desde CI:
#   ea2-cloud-lab-install-k3s.sh <pem> <server_public_ip> <server_private_ip> <agent_public_ip> <nlb_dns>
#
# Keepalive SSH: evita "Broken pipe" en CI si el download de k3s tarda y un NAT corta la sesión.
set -euo pipefail

PEM=${1:?pem}
SERVER_PUB=${2:?server public}
SERVER_PRV=${3:?server private}
AGENT_PUB=${4:?agent public}
NLB_DNS=${5:-$SERVER_PUB}

SSH_OPTS=(
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o ServerAliveInterval=15
  -o ServerAliveCountMax=120
  -o TCPKeepAlive=yes
  -o ConnectTimeout=30
  -i "$PEM"
)

remote() {
  ssh "${SSH_OPTS[@]}" "ubuntu@${1}" "${2}"
}

echo "[ea2-cloud-lab] instalando k3s server en ${SERVER_PUB}..."
remote "${SERVER_PUB}" \
  "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --write-kubeconfig-mode 644 --advertise-address ${SERVER_PRV} --node-external-ip ${SERVER_PUB} --tls-san ${SERVER_PUB} --tls-san ${NLB_DNS}' sh -"

echo "[ea2-cloud-lab] leyendo token..."
TOKEN=$(ssh "${SSH_OPTS[@]}" "ubuntu@${SERVER_PUB}" sudo cat /var/lib/rancher/k3s/server/node-token)

install_agent() {
  remote "${AGENT_PUB}" \
    "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='agent --server https://${SERVER_PRV}:6443 --token ${TOKEN} --node-external-ip ${AGENT_PUB}' sh -"
}

echo "[ea2-cloud-lab] instalando k3s agent en ${AGENT_PUB}..."
AGENT_OK=0
for attempt in $(seq 1 5); do
  if install_agent; then
    AGENT_OK=1
    break
  fi
  echo "[ea2-cloud-lab] agent intento ${attempt}/5 falló (SSH/download); esperando..."
  sleep 25
done
if [[ "${AGENT_OK}" != "1" ]]; then
  echo "[ea2-cloud-lab] falló install agent tras 5 intentos"
  exit 1
fi

echo "[ea2-cloud-lab] esperando nodos Ready..."
for _ in $(seq 1 90); do
  READY_COUNT=$(ssh "${SSH_OPTS[@]}" "ubuntu@${SERVER_PUB}" \
    "sudo kubectl get nodes --no-headers 2>/dev/null | grep -cE '[[:space:]]Ready[[:space:]]' || true")
  READY_COUNT=$(echo "${READY_COUNT}" | tr -d '[:space:]')
  if [[ "${READY_COUNT}" == "2" ]]; then
    ssh "${SSH_OPTS[@]}" "ubuntu@${SERVER_PUB}" sudo kubectl get nodes -o wide
    exit 0
  fi
  sleep 10
done

echo "[ea2-cloud-lab] timeout esperando 2 nodos Ready"
ssh "${SSH_OPTS[@]}" "ubuntu@${SERVER_PUB}" sudo kubectl get nodes -o wide || true
exit 1
