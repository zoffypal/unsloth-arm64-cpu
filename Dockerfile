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

# Do NOT install PyTorch.
# We want GGUF / llama.cpp CPU mode for Oracle Ampere A1.
ENV UNSLOTH_NO_TORCH=1

# Force llama.cpp CPU backend.
ENV UNSLOTH_LLAMA_CPP_BACKEND=cpu

# Studio llama.cpp-only mode.
ENV UNSLOTH_STUDIO_LLAMA_ONLY=1

# We are building inside Docker, so never try to launch interactively
# during installation.
ENV UNSLOTH_SKIP_AUTOSTART=1

# Use Python 3.13.
ENV UNSLOTH_PYTHON=3.13

# Keep everything self-contained.
ENV UNSLOTH_STUDIO_HOME=/opt/unsloth-studio

# Runtime PATH.
ENV PATH="/opt/unsloth-studio/bin:/opt/unsloth-studio/unsloth_studio/bin:/root/.local/bin:${PATH}"

# ---------------------------------------------------------
# Install official Unsloth Studio
# ---------------------------------------------------------

RUN curl -fsSL https://unsloth.ai/install.sh | sh

# ---------------------------------------------------------
# IMPORTANT:
# The installer installs the core package, but Studio's optional
# dependencies need to be installed explicitly for our no-torch
# image.
# ---------------------------------------------------------

RUN /root/.local/bin/uv pip install \
    --python /opt/unsloth-studio/unsloth_studio/bin/python \
    "unsloth[studio]" \
    --no-cache

# ---------------------------------------------------------
# Verify Studio installation during image build
# ---------------------------------------------------------

RUN /opt/unsloth-studio/unsloth_studio/bin/python - <<'PY'
import importlib

packages = [
    "structlog",
    "typer",
    "fastapi",
    "uvicorn",
    "pydantic",
    "matplotlib",
    "pandas",
    "jwt",
    "urllib3",
    "jinja2",
    "diceware",
    "ddgs",
    "cryptography",
    "boto3",
    "fastmcp",
    "gguf",
    "av",
]

missing = []

for pkg in packages:
    try:
        importlib.import_module(pkg)
        print(f"OK   {pkg}")
    except Exception as exc:
        print(f"FAIL {pkg}: {exc}")
        missing.append(pkg)

if missing:
    raise SystemExit(
        "Missing Studio dependencies: " + ", ".join(missing)
    )

print("All required Studio dependencies are installed.")
PY

# ---------------------------------------------------------
# Verify that PyTorch was NOT installed
# ---------------------------------------------------------

RUN ! /opt/unsloth-studio/unsloth_studio/bin/python -c \
    "import torch"

# ---------------------------------------------------------
# Workspace
# ---------------------------------------------------------

WORKDIR /workspace

RUN mkdir -p \
    /workspace/models \
    /workspace/projects \
    /workspace/cache

EXPOSE 8000

CMD ["/opt/unsloth-studio/unsloth_studio/bin/unsloth", "studio", "-H", "0.0.0.0", "-p", "8000"]
