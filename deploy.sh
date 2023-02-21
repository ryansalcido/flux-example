#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

function usage() {
  cat <<EOF
$(basename "$0") -e <ENVIRONMENT NAME>

 -e       environment/overlay to deploy
EOF
}

while getopts ":e:" opt; do
  case $opt in
    e)
      ENVIRONMENT_NAME="$OPTARG"
      ;;
    \?)
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${ENVIRONMENT_NAME-}" ]]; then
  usage
  exit 1
fi

kubectl cluster-info

export SOPS_AGE_KEY_FILE=flux-example-key.txt

# Bootstrap the environment
sops -d bootstrap.enc.yaml | kubectl apply -f -

# Install Flux
echo >&2 "Installing Flux ..."
kubectl apply -k "k8s/flux/envs/${ENVIRONMENT_NAME}"
flux check

# Deploy the environment
echo >&2 "Deploying environment ${ENVIRONMENT_NAME} ..."
kubectl apply -k "k8s/kustomizations/envs/${ENVIRONMENT_NAME}"
