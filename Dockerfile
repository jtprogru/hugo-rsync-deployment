FROM alpine:3.21@sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d

LABEL "name"="Hugo rsync deployment"
LABEL "maintainer"="Mikhail Savin <jtprogru@gmail.com>"
LABEL "version"="0.4.0"

LABEL "com.github.actions.name"="Hugo rsync deployment"
LABEL "com.github.actions.description"="An action that generates and deploys a static website using Hugo and rsync."
LABEL "com.github.actions.icon"="upload-cloud"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="https://github.com/jtprogru/hugo-rsync-deployment"
LABEL "homepage"="https://jtprog.ru/"

RUN apk -U upgrade && apk add --no-cache --upgrade --no-progress \
    curl \
    git \
    openssh \
    rsync

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
