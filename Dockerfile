FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------
# Runtime / build dependencies
# ---------------------------------------------------------
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# Unsloth Studio configuration
# ---------------------------------------------------------

# Do not install PyTorch.
# This is the important part for Oracle A1.
ENV UNSLOTH_NO_TORCH=1

# Force llama.cpp to use CPU.
ENV UNSLOTH_LLAMA_CPP_BACKEND=cpu

# Only install/use the llama.cpp path inside Studio.
ENV UNSLOTH_STUDIO_LLAMA_ONLY=1

# Prevent installer from trying to start Studio during Docker build.
ENV UNSLOTH_SKIP_AUTOSTART=1

# Use Python 3.13 through Unsloth's installer / uv.
ENV UNSLOTH_PYTHON=3.13

# Keep Studio data in a predictable location.
ENV UNSLOTH_STUDIO_HOME=/opt/unsloth-studio

# Avoid interactive terminal prompts during build.
ENV NONINTERACTIVE=1

# ---------------------------------------------------------
# Install Unsloth Studio
# ---------------------------------------------------------

RUN curl -fsSL https://unsloth.ai/install.sh | sh

# The installer normally puts uv / Unsloth commands here.
ENV PATH="/opt/unsloth-studio/bin:/opt/unsloth-studio/unsloth_studio/bin:${PATH}"

# ---------------------------------------------------------
# Cleanup build-only packages
# ---------------------------------------------------------

RUN apt-get purge -y \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    git \
    && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# ---------------------------------------------------------
# Runtime
# ---------------------------------------------------------

WORKDIR /workspace

RUN mkdir -p \
    /workspace/models \
    /workspace/projects \
    /workspace/cache

EXPOSE 8000

CMD ["unsloth", "studio", "-H", "0.0.0.0", "-p", "8000"]
