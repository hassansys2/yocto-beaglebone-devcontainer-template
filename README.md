
# Yocto Devcontainer for BeagleBone Black (BBB)  
A complete, containerized workflow for building **Yocto Kirkstone images** for **BeagleBone Black (AM335x)** on macOS using **Docker + VSCode Devcontainers**.

---

## 📌 Overview  

This repository contains:

- A **VSCode devcontainer** that sets up a full Yocto build environment  
- Docker-based **reproducible development environment**  
- Preconfigured **DL_DIR** and **SSTATE_DIR** mounts for caching  
- Instructions to build **core-image-minimal** for BeagleBone Black  

---

## 🚀 Features  

✔ Works on **macOS (Intel or M-series)**  
✔ No Yocto installation required on host  
✔ Safe, self-contained build environment  
✔ Supports **meta-ti** for AM335x (BBB)  
✔ Rebuilds are extremely fast using **sstate + download cache**  
✔ Clean and reproducible builds  

---

## 📂 Repository Structure

```
.
├── .devcontainer/
│   └── devcontainer.json
├── docker-compose.yml
├── Dockerfile
├── workspace/
│   └── (Yocto source + builds will appear here)
├── sstate/
├── downloads/
└── README.md   ← you are here
```

---

# 🐳 1. Requirements

| Component | Required |
|----------|----------|
| macOS 12+ | ✔ |
| Docker Desktop | ✔ |
| VSCode + Dev Containers extension | ✔ |
| 50–120 GB disk space | ✔ |
| 8–16 GB RAM (recommended) | ✔ |

---

# 🧰 2. Setup Instructions (From Zero)

## **Step 1 — Clone this repo**

```bash
git clone https://github.com/hassansys2/yocto-beaglebone-devcontainer-template.git
cd yocto-beaglebone-devcontainer-template
```

---

## **Step 2 — Launch Devcontainer**

Open folder in VSCode →  
**Command Palette → "Dev Containers: Reopen in Container"**

VSCode will:

- Build Docker image  
- Launch devcontainer  
- Mount workspace + caches  
- Configure Yocto environment  

---

## **Step 3 — Download Yocto (Kirkstone)**

Inside container:

```bash
cd /workspace
git clone --branch kirkstone git://git.yoctoproject.org/poky
git clone --branch kirkstone https://github.com/openembedded/meta-openembedded.git
git clone --branch kirkstone https://git.yoctoproject.org/meta-arm
git clone --branch kirkstone https://git.yoctoproject.org/meta-ti.git
```

---

## **Step 4 — Create Yocto Build Directory**

```bash
source poky/oe-init-build-env build-bbb-kirkstone
```

This creates:

```
build-bbb-kirkstone/
├── conf/bblayers.conf
├── conf/local.conf
```

---

## **Step 5 — Configure MACHINE**

Edit:

```
conf/local.conf
```

Set:

```conf
MACHINE = "am335x-evm"
DL_DIR ?= "/downloads"
SSTATE_DIR ?= "/sstate"
```

---

## **Step 6 — Add Required Layers**

```bash
bitbake-layers add-layer /workspace/meta-openembedded/meta-oe
bitbake-layers add-layer /workspace/meta-openembedded/meta-python
bitbake-layers add-layer /workspace/meta-openembedded/meta-networking
bitbake-layers add-layer /workspace/meta-arm/meta-arm-toolchain
bitbake-layers add-layer /workspace/meta-arm/meta-arm
bitbake-layers add-layer /workspace/meta-ti/meta-ti-bsp
bitbake-layers add-layer /workspace/meta-ti/meta-ti-extras
```

---

## **Step 7 — Build Yocto Image**

```bash
bitbake core-image-minimal
```

After build:

Images appear at:

```
build-bbb-kirkstone/deploy-ti/images/am335x-evm/
```

Important output files:

| File | Purpose |
|------|---------|
| `.wic.xz` | SD card image |
| `MLO` | SPL bootloader |
| `u-boot.img` | U-Boot |
| `zImage` | Kernel |
| `.dtb` | Device tree files |

---

# 🔥 3. Flashing Image to SD Card (macOS)

```bash
xz -d core-image-minimal-am335x-evm.wic.xz
diskutil list
diskutil unmountDisk /dev/diskX
sudo dd if=core-image-minimal-am335x-evm.wic of=/dev/rdiskX bs=4m status=progress
sync
```

Insert SD into BBB and boot.

---

# 🌱 4. Understanding Yocto Internals (Concept Summary)

### **MACHINE selection**
- Yocto reads `conf/machine/<machine>.conf`
- Includes kernel, SPL, U-Boot config, tuning

For example:

```
meta-ti/meta-ti-bsp/conf/machine/am335x-evm.conf
```

---

### **Layers**
Each layer has:

```
conf/layer.conf
recipes-*/...
dynamic-layers/
classes/
```

Yocto loads layers based on `bblayers.conf`.

---

### **Recipe Execution Order**

Bitbake tasks:

```
do_fetch → do_unpack → do_patch → do_configure → do_compile → do_install → do_package → do_rootfs → do_image
```

---

### **Images**

`core-image-minimal.bb` defines:

- Busybox
- Init manager
- Basic kernel modules
- Root filesystem packaging  

---

# 🧩 5. Adding Your Custom Layer (meta-hassan)

```bash
cd /workspace
bitbake-layers create-layer meta-hassan
bitbake-layers add-layer meta-hassan
```

Create custom recipes:

```
meta-hassan/recipes-apps/myapp/myapp.bb
```

---

# 📄 6. Included Devcontainer Files

### **devcontainer.json**

```json
{
  "name": "Yocto (BBB) — Dev Container",
  "dockerComposeFile": ["../docker-compose.yml"],
  "service": "yocto",
  "workspaceFolder": "/workspace",
  "remoteUser": "dev",
  "overrideCommand": false,
  "customizations": {
    "vscode": {
      "settings": {
        "terminal.integrated.defaultProfile.linux": "bash",
        "files.exclude": {
          "**/build": true,
          "**/tmp": true
        },
        "editor.tabSize": 2
      },
      "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools",
        "ms-azuretools.vscode-docker",
        "eamodio.gitlens",
        "github.vscode-pull-request-github"
      ]
    }
  },
  "postCreateCommand": "bash -lc 'git config --global --add safe.directory /workspace && sudo chown -R dev:dev /workspace /sstate /downloads || true && echo \"Devcontainer ready!\"'"
}
```

---

### **docker-compose.yml**

```yaml
version: "3.8"

services:
  yocto:
    build:
      context: .
      dockerfile: Dockerfile
    image: emb-linux:22.04
    tty: true
    stdin_open: true
    working_dir: /workspace
    environment:
      - LANG=en_US.UTF-8
      - LC_ALL=en_US.UTF-8
      - CCACHE_DIR=/home/dev/.ccache
      - DL_DIR=/downloads
      - SSTATE_DIR=/sstate
    volumes:
      - ./workspace:/workspace
      - ./sstate:/sstate
      - ./downloads:/downloads
    command: bash -lc "bash"
```

---

### **Dockerfile**

```Dockerfile
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
```

---

# 🩵 7. Troubleshooting

### **Build too slow?**
Use global mirrors:

```
INHERIT += "own-mirrors"
SOURCE_MIRROR_URL = "https://downloads.yoctoproject.org/mirror/sources/"
BB_FETCH_PREMIRRORONLY = "1"
```

---

### **macOS Sleep Issue**
Prevent mac sleep during build:

```bash
caffeinate -dims &
```

---

# 🎉 8. You're Ready!

You now have a **full Yocto build environment** on macOS using Docker.

---

# 📜 License  
MIT — free for learning & commercial usage.

---
