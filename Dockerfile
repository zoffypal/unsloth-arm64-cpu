FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------
# System dependencies
# ---------------------------------------------------------

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# Unsloth configuration
# ---------------------------------------------------------

# IMPORTANT:
# Do NOT install PyTorch.
ENV UNSLOTH_NO_TORCH=1

# CPU llama.cpp
ENV UNSLOTH_LLAMA_CPP_BACKEND=cpu

# GGUF / llama.cpp oriented Studio
ENV UNSLOTH_STUDIO_LLAMA_ONLY=1

# Docker build should never try to launch Studio interactively
ENV UNSLOTH_SKIP_AUTOSTART=1

ENV UNSLOTH_PYTHON=3.13

# Keep everything inside one predictable directory
ENV UNSLOTH_STUDIO_HOME=/opt/unsloth-studio

ENV PATH="/opt/unsloth-studio/bin:/opt/unsloth-studio/unsloth_studio/bin:/root/.local/bin:${PATH}"

# ---------------------------------------------------------
# Official Unsloth installation
# ---------------------------------------------------------

RUN curl -fsSL https://unsloth.ai/install.sh | sh

# ---------------------------------------------------------
# IMPORTANT:
# Force the official Studio setup/update path once more.
#
# This lets Unsloth itself install studio.txt WITH normal
# dependencies while preserving the no-torch mode.
# ---------------------------------------------------------

RUN UNSLOTH_NO_TORCH=1 \
    /opt/unsloth-studio/bin/unsloth studio update

# ---------------------------------------------------------
# Verification
# ---------------------------------------------------------

RUN /opt/unsloth-studio/unsloth_studio/bin/python - <<'PY'
import platform

print("Architecture:", platform.machine())
PY

# Check important Studio imports
RUN /opt/unsloth-studio/unsloth_studio/bin/python - <<'PY'
import structlog
import typer
import fastapi
import uvicorn
import pydantic
import pandas
import matplotlib
import gguf
import av

print("Studio core dependencies: OK")
PY

# Confirm that PyTorch is NOT installed
RUN /opt/unsloth-studio/unsloth_studio/bin/python - <<'PY'
import importlib.util

if importlib.util.find_spec("torch") is not None:
    raise SystemExit("ERROR: PyTorch is installed, but this image must be no-torch.")

print("PyTorch: NOT installed")
PY

# ---------------------------------------------------------
# Workspace
# ---------------------------------------------------------

WORKDIR /workspace

RUN mkdir -p \
    /workspace/models \
    /workspace/projects \
    /workspace/cache

EXPOSE 8000

CMD ["/opt/unsloth-studio/bin/unsloth", "studio", "-H", "0.0.0.0", "-p", "8000"]
