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
# Skip PyTorch completely.
ENV UNSLOTH_NO_TORCH=1

# Use CPU llama.cpp.
ENV UNSLOTH_LLAMA_CPP_BACKEND=cpu

# GGUF / llama.cpp oriented Studio.
ENV UNSLOTH_STUDIO_LLAMA_ONLY=1

# Do not auto-start Studio during installation.
ENV UNSLOTH_SKIP_AUTOSTART=1

ENV UNSLOTH_PYTHON=3.13

# Keep Unsloth isolated inside the image.
ENV UNSLOTH_STUDIO_HOME=/opt/unsloth-studio

ENV PATH="/opt/unsloth-studio/bin:/opt/unsloth-studio/unsloth_studio/bin:/root/.local/bin:${PATH}"

# ---------------------------------------------------------
# Install Unsloth using the official installer
# ---------------------------------------------------------

RUN curl -fsSL https://unsloth.ai/install.sh | sh

# ---------------------------------------------------------
# Install the Studio-specific dependencies WITHOUT
# dependency resolution.
#
# This avoids pulling PyTorch back into the image.
# ---------------------------------------------------------

RUN /root/.local/bin/uv pip install \
    --python /opt/unsloth-studio/unsloth_studio/bin/python \
    --no-deps \
    -r /opt/unsloth-studio/unsloth_studio/lib/python3.13/site-packages/studio/backend/requirements/studio.txt

# ---------------------------------------------------------
# Verify architecture
# ---------------------------------------------------------

RUN /opt/unsloth-studio/unsloth_studio/bin/python -c \
    "import platform; print('Architecture:', platform.machine())"

# ---------------------------------------------------------
# Verify Studio dependencies
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

for name in packages:
    try:
        importlib.import_module(name)
        print(f"OK   {name}")
    except Exception as e:
        print(f"FAIL {name}: {e}")
        missing.append(name)

if missing:
    raise SystemExit(
        "Missing packages: " + ", ".join(missing)
    )

print("All Studio dependencies are present.")
PY

# ---------------------------------------------------------
# Verify that PyTorch is NOT installed
# ---------------------------------------------------------

RUN /opt/unsloth-studio/unsloth_studio/bin/python -c \
    "import importlib.util; raise SystemExit(1 if importlib.util.find_spec('torch') else 0)"

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
