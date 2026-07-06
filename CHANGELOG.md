# Changelog

## 0.4.0 (2026/07/06)
* Verify the downloaded Hugo archive against its published SHA-256 checksum
* Select the Hugo binary for the runner architecture (amd64 / arm64) — ARM runners now work
* Add `hugo-extended` input to install the Hugo Extended build (SCSS/SASS)
* Add `ssh-port` input for servers on a non-standard SSH port
* Validate `GITHUB_WORKSPACE` and the `VPS_DEPLOY_*` secrets up front with clear error messages
* Fail fast on a failed Hugo download (`curl --fail`) instead of an obscure `tar` error
* Rely on `ssh-keyscan`-populated `known_hosts` instead of disabling host key checking
* Harden SSH setup (`mkdir -p`/`chmod 700` for `~/.ssh`, `printf` instead of `echo` for the key)
* Pin the Alpine base image by digest

## 0.1.6 (2020/08/26)
* More loggin
* Improved readme

## 0.1.5 (2020/08/26)
* Updated Alpine version

## 0.1.4 (2020/08/26)
* Initial version
