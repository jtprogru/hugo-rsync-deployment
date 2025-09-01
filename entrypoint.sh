#!/bin/sh -l

set -euo pipefail

if [[ -z "$GITHUB_WORKSPACE" ]]; then
    echo "Set the GITHUB_WORKSPACE env variable."
    exit 1
fi

cd "${GITHUB_WORKSPACE}/"

git config --global --add safe.directory '*'

COMMIT=$(git rev-parse --short HEAD)

sed -i -e "s/@@@COMMIT@@@/${COMMIT}/g" hugo.yaml

hugo version
hugo $1

mkdir "${HOME}/.ssh"
echo "${VPS_DEPLOY_KEY}" >"${HOME}/.ssh/id_rsa_deploy"
chmod 600 "${HOME}/.ssh/id_rsa_deploy"

ssh-keyscan -p 22 ${VPS_DEPLOY_HOST} >~/.ssh/known_hosts

echo "Rewrite robots.txt"

cp ${GITHUB_WORKSPACE}/content/robots.txt ${GITHUB_WORKSPACE}/public/robots.txt

rsync --version
sh -c "
rsync -avhz --progress \
  -e 'ssh -i ${HOME}/.ssh/id_rsa_deploy -o StrictHostKeyChecking=no' \
  ${GITHUB_WORKSPACE}/public/ \
  ${VPS_DEPLOY_USER}@${VPS_DEPLOY_HOST}:${VPS_DEPLOY_DEST}/ --delete
"

exit 0
