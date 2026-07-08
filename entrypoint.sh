#!/bin/sh -l

set -eu

HUGO_ARGS="${1:-}"
RSYNC_ARGS="${2:-}"
HUGO_VERSION="${3:-0.160.1}"
HUGO_CONFIG="${4:-}"
ROBOTS_TXT_SOURCE="${5:-}"
HUGO_EXTENDED="${6:-false}"
SSH_PORT="${7:-22}"

if [ -z "${GITHUB_WORKSPACE:-}" ]; then
    echo "Set the GITHUB_WORKSPACE env variable."
    exit 1
fi

for var in VPS_DEPLOY_KEY VPS_DEPLOY_USER VPS_DEPLOY_HOST VPS_DEPLOY_DEST; do
    eval "value=\${${var}:-}"
    if [ -z "$value" ]; then
        echo "Set the ${var} secret."
        exit 1
    fi
done

cd "${GITHUB_WORKSPACE}/"

git config --global --add safe.directory '*'

# Resolve the Hugo release asset for the current architecture.
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64 | amd64) HUGO_ARCH="linux-amd64" ;;
    aarch64 | arm64) HUGO_ARCH="linux-arm64" ;;
    *)
        echo "Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

HUGO_VARIANT="hugo"
if [ "$HUGO_EXTENDED" = "true" ]; then
    HUGO_VARIANT="hugo_extended"
fi

HUGO_ASSET="${HUGO_VARIANT}_${HUGO_VERSION}_${HUGO_ARCH}.tar.gz"
HUGO_BASE_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}"

WORKDIR="$(mktemp -d)"

echo "Installing Hugo ${HUGO_VERSION} (${HUGO_VARIANT}, ${HUGO_ARCH})..."
curl -fsSL "${HUGO_BASE_URL}/${HUGO_ASSET}" -o "${WORKDIR}/${HUGO_ASSET}"
curl -fsSL "${HUGO_BASE_URL}/hugo_${HUGO_VERSION}_checksums.txt" -o "${WORKDIR}/checksums.txt"

# Verify the download against the published SHA-256 checksum.
( cd "${WORKDIR}" && grep " ${HUGO_ASSET}\$" checksums.txt | sha256sum -c - )

tar xf "${WORKDIR}/${HUGO_ASSET}" hugo -C "${WORKDIR}/"
cp "${WORKDIR}/hugo" /usr/bin/hugo
rm -rf "${WORKDIR}"

if [ -n "$HUGO_CONFIG" ] && [ -f "$HUGO_CONFIG" ]; then
    COMMIT=$(git rev-parse --short HEAD)
    sed -i -e "s/@@@COMMIT@@@/${COMMIT}/g" "${HUGO_CONFIG}"
fi

hugo version
# shellcheck disable=SC2086 # intentional word splitting of build flags
hugo ${HUGO_ARGS}

if [ -n "$ROBOTS_TXT_SOURCE" ] && [ -f "${GITHUB_WORKSPACE}/${ROBOTS_TXT_SOURCE}" ]; then
    cp "${GITHUB_WORKSPACE}/${ROBOTS_TXT_SOURCE}" "${GITHUB_WORKSPACE}/public/robots.txt"
fi

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"
printf '%s\n' "${VPS_DEPLOY_KEY}" > "${HOME}/.ssh/id_rsa_deploy"
chmod 600 "${HOME}/.ssh/id_rsa_deploy"

# Pre-seed known_hosts via ssh-keyscan. Some hosts (fail2ban / throttling on
# shared hosting) silently drop the bare keyscan probe, leaving the file empty;
# accept-new below is the fallback so an empty scan doesn't break the deploy.
ssh-keyscan -T 10 -p "${SSH_PORT}" "${VPS_DEPLOY_HOST}" > "${HOME}/.ssh/known_hosts" 2>/dev/null || true
if [ ! -s "${HOME}/.ssh/known_hosts" ]; then
    echo "WARN: ssh-keyscan returned no host key for ${VPS_DEPLOY_HOST}:${SSH_PORT}; relying on StrictHostKeyChecking=accept-new"
fi

rsync --version
# shellcheck disable=SC2086 # intentional word splitting of rsync flags
rsync ${RSYNC_ARGS} \
    -e "ssh -i ${HOME}/.ssh/id_rsa_deploy -p ${SSH_PORT} -o StrictHostKeyChecking=accept-new" \
    "${GITHUB_WORKSPACE}/public/" \
    "${VPS_DEPLOY_USER}@${VPS_DEPLOY_HOST}:${VPS_DEPLOY_DEST}/"

exit 0
