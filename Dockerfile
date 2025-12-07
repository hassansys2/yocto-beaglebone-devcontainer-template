FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash-completion build-essential bc bison flex libssl-dev \
    libncurses5-dev libncursesw5-dev libelf-dev \
    gawk wget git curl ca-certificates rsync file xz-utils zstd \
    cpio unzip zip tar python3 python3-pip python3-venv python3-distutils \
    locales sudo pkg-config cmake ninja-build meson \
    u-boot-tools device-tree-compiler \
    texinfo chrpath diffstat socat bc \
    liblz4-tool zlib1g-dev \
    ccache ssh pass vim nano tmux \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

ARG USER=dev
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} ${USER} && \
    useradd -m -u ${UID} -g ${GID} -G sudo -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_${USER}

RUN mkdir -p /home/dev/.ccache

USER dev
WORKDIR /workspace

