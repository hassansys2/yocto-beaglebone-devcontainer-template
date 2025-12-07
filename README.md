
# Yocto Devcontainer for BeagleBone Black (BBB)  
A complete, containerized workflow for building **Yocto Kirkstone images** for **BeagleBone Black (AM335x)** on macOS using **Docker + VSCode Devcontainers**.

---

## 📌 Overview  

This repository contains:

- A **VSCode devcontainer** that sets up a full Yocto build environment  
- Docker-based **reproducible development environment**  
- **Shared cache directories by default** — multiple instances share downloads and sstate cache  
- Preconfigured **DL_DIR** and **SSTATE_DIR** mounts for caching  
- Instructions to build **core-image-minimal** for BeagleBone Black  

---

## 🚀 Features  

✔ Works on **macOS (Intel or M-series)**  
✔ No Yocto installation required on host  
✔ Safe, self-contained build environment  
✔ Supports **meta-ti** for AM335x (BBB)  
✔ Rebuilds are extremely fast using **sstate + download cache**  
✔ **Shared caches enabled by default** — multiple instances share downloads and sstate cache  
✔ Clean and reproducible builds  

---

## 📂 Repository Structure

```
.
├── .devcontainer/
│   └── devcontainer.json
├── .env                    ← Pre-configured for shared caches
├── docker-compose.yml
├── Dockerfile
├── workspace/
│   └── (Yocto source + builds will appear here)
├── sstate/                 ← Local cache (fallback)
├── downloads/              ← Local cache (fallback)
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

## **Step 2 — Create Shared Cache Directories (One-time setup)**

This repository is configured to use **shared cache directories** by default (via `.env` file). This allows multiple instances to share downloads and sstate cache, saving disk space and speeding up builds.

Create the shared cache directories:

```bash
mkdir -p ~/yocto-shared/sstate
mkdir -p ~/yocto-shared/downloads
```

**Note:** The `.env` file is already configured to use these directories. If you prefer per-instance caches, see [Section 8.1](#81-using-per-instance-caches-optional) for instructions.

---

## **Step 3 — Launch Devcontainer**

Open folder in VSCode →  
**Command Palette → "Dev Containers: Reopen in Container"**

VSCode will:

- Build Docker image  
- Launch devcontainer  
- Mount workspace + **shared caches** (from `~/yocto-shared/`)  
- Configure Yocto environment  

The `.env` file is automatically loaded by Docker Compose, so shared caches are used by default.

---

## **Step 4 — Download Yocto (Kirkstone)**

Inside container:

```bash
cd /workspace
git clone --branch kirkstone git://git.yoctoproject.org/poky
git clone --branch kirkstone https://github.com/openembedded/meta-openembedded.git
git clone --branch kirkstone https://git.yoctoproject.org/meta-arm
git clone --branch kirkstone https://git.yoctoproject.org/meta-ti.git
```

---

## **Step 5 — Create Yocto Build Directory**

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

## **Step 6 — Configure MACHINE**

Edit:

```
conf/local.conf
```

Set:

```conf
MACHINE = "am335x-evm"
DL_DIR ?= "/downloads"
SSTATE_DIR ?= "/sstate"
TMPDIR = "/tmp/yocto/tmp-bbb-kirkstone"
```

---

## **Step 7 — Add Required Layers**

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

## **Step 8 — Build Yocto Image**

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
      # Cache directories: Shared caches are enabled by default via .env file
      # Falls back to local ./sstate and ./downloads if env vars are not set
      - ${YOCTO_SHARED_SSTATE_DIR:-./sstate}:/sstate
      - ${YOCTO_SHARED_DOWNLOADS_DIR:-./downloads}:/downloads
    # Resource limits: Uncomment and adjust values to limit resource usage
    # Useful when running multiple instances simultaneously
    # deploy:
    #   resources:
    #     limits:
    #       cpus: '4'
    #       memory: 8G
    #     reservations:
    #       cpus: '2'
    #       memory: 4G
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

# 🔄 8. Running Multiple Instances

This repository is **pre-configured for multiple instances** with shared cache directories. All instances automatically share downloads and sstate cache, saving disk space and speeding up builds.

---

## **8.1 Shared Caches (Default Configuration)**

**Shared caches are enabled by default** via the included `.env` file:

```bash
YOCTO_SHARED_SSTATE_DIR=${HOME}/yocto-shared/sstate
YOCTO_SHARED_DOWNLOADS_DIR=${HOME}/yocto-shared/downloads
```

### **Benefits:**
- ✅ **Save disk space** — downloads are shared across all instances
- ✅ **Faster builds** — sstate cache is shared (rebuilds are much faster)
- ✅ **Reduce bandwidth** — downloads happen once, reused by all instances
- ✅ **No configuration needed** — works out of the box

### **How It Works:**
1. Each instance clones this repository (with `.env` file)
2. All instances point to the same shared cache directories (`~/yocto-shared/`)
3. First build downloads everything, subsequent builds reuse cache
4. Each instance maintains its own `workspace/` directory (builds are isolated)

### **Example: Multiple Projects**

```bash
# Project A
cd ~/projects/yocto-bbb-project-a
git clone https://github.com/hassansys2/yocto-beaglebone-devcontainer-template.git .
# .env file is already included - shared caches work automatically!

# Project B  
cd ~/projects/yocto-bbb-project-b
git clone https://github.com/hassansys2/yocto-beaglebone-devcontainer-template.git .
# Also uses shared caches automatically!
```

Both projects will share the same cache, but have separate build workspaces.

---

## **8.1.1 Using Per-Instance Caches (Optional)**

If you need **isolated caches** per instance (e.g., different Yocto versions, testing cache behavior), you can disable shared caches:

### **Option 1: Remove or rename .env file**

```bash
# Rename .env to disable shared caches
mv .env .env.disabled
```

The instance will fall back to local `./sstate` and `./downloads` directories.

### **Option 2: Modify .env file**

Edit `.env` and comment out or remove the shared cache variables:

```bash
# YOCTO_SHARED_SSTATE_DIR=${HOME}/yocto-shared/sstate
# YOCTO_SHARED_DOWNLOADS_DIR=${HOME}/yocto-shared/downloads
```

The instance will use local per-instance caches.

---

## **8.2 Resource Limits**

When running multiple instances simultaneously, limit resource usage to prevent system overload.

### **Enable Resource Limits**

Edit `docker-compose.yml` and uncomment the `deploy.resources` section:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'      # Limit to 4 CPU cores
      memory: 8G     # Limit to 8GB RAM
    reservations:
      cpus: '2'      # Reserve 2 CPU cores
      memory: 4G     # Reserve 4GB RAM
```

**Recommended limits per instance:**
- **CPU**: 2-4 cores (adjust based on total CPU cores)
- **Memory**: 6-8GB (Yocto builds are memory-intensive)

---

## **8.3 Best Practices**

### **✅ Do:**
- **Use shared caches** (default) — all instances automatically share caches
- Set resource limits when running 2+ instances simultaneously
- Monitor disk space (shared cache + each build workspace needs 50-120GB)
- Use different `workspace/` directories per instance (already isolated)
- Create shared cache directories once (Step 2 in setup)

### **❌ Don't:**
- Run more than 2-3 instances simultaneously (unless you have 32+ GB RAM)
- Share caches between different Yocto versions (e.g., Kirkstone vs. Dunfell) — use per-instance caches for different versions
- Share `workspace/` directories (builds must be isolated)
- Delete `.env` file unless you need per-instance caches

---

## **8.4 Example: Two Instances**

**Instance 1** (Project A):
```bash
cd ~/projects/yocto-bbb-project-a
git clone https://github.com/hassansys2/yocto-beaglebone-devcontainer-template.git .
# .env file is included - shared caches configured automatically!
# Open in VSCode → Reopen in Container
```

**Instance 2** (Project B):
```bash
cd ~/projects/yocto-bbb-project-b
git clone https://github.com/hassansys2/yocto-beaglebone-devcontainer-template.git .
# .env file is included - shared caches configured automatically!
# Open in VSCode → Reopen in Container
```

**No additional configuration needed!** Both instances will:
- ✅ Share sstate cache (faster rebuilds)
- ✅ Share downloads (saves disk/bandwidth)
- ✅ Use separate workspaces (no build conflicts)
- ✅ Work out of the box (`.env` file handles everything)

---

## **8.5 Resource Usage Estimate**

| Scenario | Instances | Total RAM | Total Disk | Build Time |
|----------|-----------|-----------|------------|------------|
| Single instance (shared cache) | 1 | ~12GB | ~80GB | 4 hours |
| Two instances (shared cache - **default**) | 2 | ~24GB | ~100GB | 6-8 hours |
| Two instances (separate cache) | 2 | ~24GB | ~160GB | 8-10 hours |

**Note:** 
- Shared cache (default) saves ~60GB disk space for two instances
- Build times increase due to resource contention when running multiple instances
- First build downloads everything, subsequent builds are much faster due to shared cache

---

# 🎉 9. You're Ready!

You now have a **full Yocto build environment** on macOS using Docker.

---

# 📜 License  
MIT — free for learning & commercial usage.

---
