#!/bin/sh -l

set -eu

HUGO_ARGS="${1:-}"
RSYNC_ARGS="${2:-}"
HUGO_VERSION="${3:-0.160.1}"
HUGO_CONFIG="${4:-}"
ROBOTS_TXT_SOURCE="${5:-}"

if [ -z "$GITHUB_WORKSPACE" ]; then
    echo "Set the GITHUB_WORKSPACE env variable."
    exit 1
fi

cd "${GITHUB_WORKSPACE}/"

git config --global --add safe.directory '*'

echo "Installing Hugo ${HUGO_VERSION}..."
curl -sSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz" -o /tmp/hugo.tar.gz
tar xf /tmp/hugo.tar.gz hugo -C /tmp/
cp /tmp/hugo /usr/bin/hugo
rm /tmp/hugo.tar.gz

if [ -n "$HUGO_CONFIG" ] && [ -f "$HUGO_CONFIG" ]; then
    COMMIT=$(git rev-parse --short HEAD)
    sed -i -e "s/@@@COMMIT@@@/${COMMIT}/g" "${HUGO_CONFIG}"
fi

hugo version
hugo ${HUGO_ARGS}

if [ -n "$ROBOTS_TXT_SOURCE" ] && [ -f "${GITHUB_WORKSPACE}/${ROBOTS_TXT_SOURCE}" ]; then
    cp "${GITHUB_WORKSPACE}/${ROBOTS_TXT_SOURCE}" "${GITHUB_WORKSPACE}/public/robots.txt"
fi

mkdir "${HOME}/.ssh"
echo "${VPS_DEPLOY_KEY}" > "${HOME}/.ssh/id_rsa_deploy"
chmod 600 "${HOME}/.ssh/id_rsa_deploy"

ssh-keyscan -p 22 ${VPS_DEPLOY_HOST} > ~/.ssh/known_hosts

rsync --version
rsync ${RSYNC_ARGS} \
    -e "ssh -i ${HOME}/.ssh/id_rsa_deploy -o StrictHostKeyChecking=no" \
    "${GITHUB_WORKSPACE}/public/" \
    "${VPS_DEPLOY_USER}@${VPS_DEPLOY_HOST}:${VPS_DEPLOY_DEST}/"

exit 0
