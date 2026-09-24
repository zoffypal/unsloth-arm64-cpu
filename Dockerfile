FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

# =========================================================
# Versions
# =========================================================

ARG PYTHON_VERSION=3.13

# =========================================================
# System dependencies
# =========================================================

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    unzip \
    zip \
    xz-utils \
    bzip2 \
    file \
    rsync \
    jq \
    procps \
    lsof \
    ffmpeg \
    \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    \
    libssl-dev \
    libffi-dev \
    libopenblas-dev \
    \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    \
    libstdc++6 \
    libgcc-s1 \
    libgomp1 \
    zlib1g \
    \
    && rm -rf /var/lib/apt/lists/*

# =========================================================
# Unsloth installation configuration
# =========================================================

# Python version used by Unsloth's installer.
ENV UNSLOTH_PYTHON=${PYTHON_VERSION}

# Use a private/self-contained Studio installation.
ENV UNSLOTH_STUDIO_HOME=/opt/unsloth-studio

# IMPORTANT:
#
# We DO NOT set UNSLOTH_NO_TORCH.
#
# We want the complete Unsloth Python stack, but CPU-only.
#

# Explicitly force PyTorch CPU wheels.
#
# This prevents the installer from ever selecting CUDA wheels.
ENV UNSLOTH_TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu

# Explicitly record CPU backend.
ENV UNSLOTH_TORCH_BACKEND=cpu

# Tell the Studio installer that this is an intentional full
# dependency installation.
ENV UNSLOTH_STUDIO_FULL_DEPS=1

# llama.cpp should use CPU.
ENV UNSLOTH_LLAMA_CPP_BACKEND=cpu

# Do not start Studio during Docker build.
ENV UNSLOTH_SKIP_AUTOSTART=1

# Isolate uv cache inside the image build.
ENV UNSLOTH_ISOLATE_UV_CACHE=1

# Runtime PATH.
ENV PATH="/opt/unsloth-studio/bin:/opt/unsloth-studio/unsloth_studio/bin:/root/.local/bin:${PATH}"

# =========================================================
# Install Unsloth using the official upstream installer
# =========================================================

RUN curl -fsSL https://unsloth.ai/install.sh | sh

# =========================================================
# Verify Python
# =========================================================

RUN /opt/unsloth-studio/unsloth_studio/bin/python \
    --version

# =========================================================
# Verify ARM64
# =========================================================

RUN /opt/unsloth-studio/unsloth_studio/bin/python - <<'PY'
import platform
import sys

print("Python:", sys.version)
print("Machine:", platform.machine())

assert platform.machine() in ("aarch64", "arm64"), \
    f"Expected ARM64, got {platform.machine()}"
PY

# =========================================================
# Verify PyTorch is CPU-only
# =========================================================

RUN /opt/unsloth-studio/unsloth_studio/bin/python - <<'PY'
import torch

print("PyTorch:", torch.__version__)
print("CUDA version:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())

assert torch.cuda.is_available() is False, \
    "CUDA must NOT be available in the CPU-only image"

print("CPU PyTorch: OK")
PY

# =========================================================
# Verify Unsloth
# =========================================================

RUN /opt/unsloth-studio/unsloth_studio/bin/python - <<'PY'
import unsloth

print("Unsloth:", getattr(unsloth, "__version__", "unknown"))
print("Unsloth import: OK")
PY

# =========================================================
# Verify Studio dependencies
# =========================================================

RUN /opt/unsloth-studio/unsloth_studio/bin/python - <<'PY'
import structlog
import typer
import fastapi
import uvicorn
import pydantic
import matplotlib
import pandas
import jwt
import urllib3
import jinja2
import cryptography
import boto3
import fastmcp
import gguf
import av

print("Studio Python dependencies: OK")
PY

# =========================================================
# Verify llama.cpp
# =========================================================

RUN set -eux; \
    if [ -x "/opt/unsloth-studio/llama.cpp/llama-server" ]; then \
        /opt/unsloth-studio/llama.cpp/llama-server --version; \
    elif command -v llama-server >/dev/null 2>&1; then \
        llama-server --version; \
    else \
        echo "ERROR: llama-server not found"; \
        find /opt/unsloth-studio -maxdepth 4 \
            -type f \
            \( -name "llama-server" -o -name "llama-cli" \) \
            -print; \
        exit 1; \
    fi

# =========================================================
# Verify Unsloth CLI
# =========================================================

RUN /opt/unsloth-studio/bin/unsloth --help

# =========================================================
# Workspace
# =========================================================

WORKDIR /workspace

RUN mkdir -p \
    /workspace/host \
    /workspace/models \
    /workspace/projects \
    /workspace/cache \
    /workspace/outputs

# HuggingFace cache
ENV HF_HOME=/workspace/cache/huggingface
ENV HF_HUB_CACHE=/workspace/cache/huggingface/hub
ENV TRANSFORMERS_CACHE=/workspace/cache/huggingface

# =========================================================
# Network
# =========================================================

EXPOSE 8000

# =========================================================
# Startup
# =========================================================

CMD ["/opt/unsloth-studio/bin/unsloth", "studio", "-H", "0.0.0.0", "-p", "8000"]
