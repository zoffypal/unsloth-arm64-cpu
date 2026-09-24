# Minimal ARM64 image for Unsloth on Oracle A1 / arm64 CPU-only hosts.
# This intentionally omits NVIDIA, CUDA, bitsandbytes, and GPU-specific packages.
FROM --platform=$TARGETPLATFORM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install the base Unsloth package without CUDA / GPU extras.
# If you want a specific release, pin it here: unsloth==<version>
RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install --no-cache-dir "unsloth"

CMD ["bash"]
