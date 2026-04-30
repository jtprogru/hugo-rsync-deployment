# Hugo rsync deployment

Why would you use a CMS if you have [GitHub Actions](https://github.com/features/actions), [Hugo](https://gohugo.io) and [rsync](https://linux.die.net/man/1/rsync)?

This action generates a static website using Hugo and deploys the public files to a remote server using rsync over SSH.

## Requirements

Before deploying from GitHub, you need to set up a few things.  
Assuming the deploy user is `github` and the host is `static-website.com`:

1. SSH access from GitHub to the webserver with the public key uploaded to `/home/github/.ssh/authorized_keys`.
1. A GitHub repository (can be private) with the following secrets configured under *Settings → Secrets*:
   - `VPS_DEPLOY_KEY` — SSH private key
   - `VPS_DEPLOY_USER` — remote username
   - `VPS_DEPLOY_HOST` — remote hostname
   - `VPS_DEPLOY_DEST` — remote destination path

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `hugo-version` | no | `0.160.1` | Hugo version to install at runtime |
| `hugo-arguments` | no | `--minify` | Extra arguments passed to `hugo` build command |
| `hugo-config` | no | `` (empty) | Config file name in which `@@@COMMIT@@@` is replaced with the current git short SHA. Leave empty to skip. |
| `rsync-arguments` | no | `--archive --compress --delete` | Arguments passed to `rsync` |
| `robots-txt-source` | no | `` (empty) | Path to `robots.txt` relative to repo root to copy into `public/` after Hugo build. Leave empty to skip. |

## Example

```yaml
name: 'Generate and deploy'

on:
  push:
    branches: [ main ]

jobs:
  deploy-website:
    runs-on: ubuntu-latest
    steps:
      - name: Do a git checkout including submodules
        uses: actions/checkout@master
        with:
          submodules: true

      - name: Generate and deploy website
        uses: jtprogru/hugo-rsync-deployment@master
        env:
          VPS_DEPLOY_KEY: ${{ secrets.VPS_DEPLOY_KEY }}
          VPS_DEPLOY_USER: ${{ secrets.DEPLOY_USER }}
          VPS_DEPLOY_HOST: ${{ secrets.DEPLOY_HOST }}
          VPS_DEPLOY_DEST: ${{ secrets.DEPLOY_TARGET_PATH }}
        with:
          hugo-version: '0.160.1'
          hugo-arguments: '--minify'
          rsync-arguments: '--archive --compress --delete'
```

### Copying robots.txt into public/

Hugo does not copy files from `content/` to `public/` by default unless they have front matter. Use `robots-txt-source` to place a plain `robots.txt` into the generated site:

```yaml
        with:
          robots-txt-source: 'content/robots.txt'
```

### Injecting git commit into Hugo config

If your Hugo config contains the placeholder `@@@COMMIT@@@`, the action can replace it with the current git short SHA at build time:

```yaml
        with:
          hugo-version: '0.160.1'
          hugo-config: 'hugo.yaml'
```

## Hugo

Some Hugo commands that can help:

```sh
hugo version         # compare the local version with what the action uses
hugo server          # run the website locally
hugo                 # generate the static website
hugo --minify        # minify CSS, JS, JSON, HTML, SVG and XML resources
```

## rsync

Useful rsync flags:

```sh
--archive, -a     # archive mode (recursive, links, permissions, times, group, owner)
--compress, -z    # compress file data during transfer
--delete          # delete extraneous files from destination
--dry-run         # trial run with no changes made
--exclude=PATTERN # exclude files matching PATTERN
--quiet, -q       # suppress non-error messages
```

## Credits

This repository is a fork of [ronvanderheijden/hugo-rsync-deployment](https://github.com/ronvanderheijden/hugo-rsync-deployment) by [Ron van der Heijden](https://ronvanderheijden.nl/). Thanks to the original author for the foundation this action is built on.

## Support

Found a bug? Got a feature request? [Create an issue](https://github.com/jtprogru/hugo-rsync-deployment/issues).

## License

Hugo rsync deployment is open source and licensed under [the MIT licence](https://github.com/jtprogru/hugo-rsync-deployment/blob/master/LICENSE.txt).
