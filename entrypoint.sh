#!/bin/sh -l

set -euo pipefail

if [[ -z "$GITHUB_WORKSPACE" ]]; then
  echo "Set the GITHUB_WORKSPACE env variable."
  exit 1
fi

cd "${GITHUB_WORKSPACE}/"

COMMIT=$(git rev-parse --short HEAD)

sed -i -e "s/@@@COMMIT@@@/${COMMIT}/g" config.yml


hugo version
hugo $1

mkdir "${HOME}/.ssh"
echo "${VPS_DEPLOY_KEY}" > "${HOME}/.ssh/id_rsa_deploy"
chmod 600 "${HOME}/.ssh/id_rsa_deploy"

ssh-keyscan -p 22 ${VPS_DEPLOY_HOST} > ~/.ssh/known_hosts

rsync --version
sh -c "
rsync -avhz --progress \
  -e 'ssh -i ${HOME}/.ssh/id_rsa_deploy -o StrictHostKeyChecking=no' \
  ${GITHUB_WORKSPACE}/public/ \
  ${VPS_DEPLOY_USER}@${VPS_DEPLOY_HOST}:${VPS_DEPLOY_DEST}/ --delete
"

exit 0
