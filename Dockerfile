FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Unsloth installation root
ENV HOME=/root

# Unsloth Studio configuration
ENV UNSLOTH_STUDIO_HOME=/root/.unsloth/studio
ENV UNSLOTH_LLAMA_CPP_PATH=/root/.unsloth/llama.cpp
ENV UNSLOTH_LLAMA_CPP_BACKEND=cpu

# Make installed CLI available
ENV PATH=/root/.local/bin:$PATH

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    bash \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Unsloth in official no-torch mode.
#
# This skips PyTorch/CUDA and installs the GGUF/CPU runtime.
RUN curl -fsSL https://unsloth.ai/install.sh \
    -o /tmp/install.sh && \
    chmod +x /tmp/install.sh && \
    UNSLOTH_NO_TORCH=1 \
    UNSLOTH_SKIP_AUTOSTART=1 \
    UNSLOTH_STUDIO_HOME=/root/.unsloth/studio \
    /bin/sh /tmp/install.sh && \
    rm -f /tmp/install.sh

# Force CPU llama.cpp backend
ENV UNSLOTH_LLAMA_CPP_BACKEND=cpu

EXPOSE 8000
EXPOSE 8888

CMD ["unsloth", "studio", "-H", "0.0.0.0", "-p", "8000"]
