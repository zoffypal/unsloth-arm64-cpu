FROM python:3.12-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    CUDA_VISIBLE_DEVICES='' \
    NVIDIA_VISIBLE_DEVICES=void \
    HF_HOME=/workspace/cache/huggingface \
    HF_HUB_CACHE=/workspace/cache/huggingface/hub \
    TRANSFORMERS_CACHE=/workspace/cache/huggingface

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        libgomp1 \
        procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN mkdir -p \
    /workspace/host \
    /workspace/models \
    /workspace/projects \
    /workspace/cache \
    /workspace/outputs

RUN pip install --upgrade pip setuptools wheel \
    && pip install --index-url https://download.pytorch.org/whl/cpu \
        --extra-index-url https://pypi.org/simple \
        --no-cache-dir \
        torch torchvision torchaudio unsloth

RUN python - <<'PY'
import platform
import torch
import unsloth

print('machine:', platform.machine())
print('torch:', torch.__version__)
print('cuda_available:', torch.cuda.is_available())
print('unsloth:', getattr(unsloth, '__version__', 'unknown'))

assert platform.machine() in ('aarch64', 'arm64'), platform.machine()
assert torch.cuda.is_available() is False, 'CUDA must be disabled in this CPU-only image'
print('CPU-only ARM64 Unsloth image: OK')
PY

CMD ["bash"]
