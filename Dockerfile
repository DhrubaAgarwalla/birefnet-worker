FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install Python
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set Python alias
RUN ln -sf /usr/bin/python3.10 /usr/bin/python

WORKDIR /app

# Install PyTorch + dependencies
RUN pip install --no-cache-dir \
    torch==2.1.2 \
    torchvision==0.16.2 \
    --index-url https://download.pytorch.org/whl/cu121

# Install BiRefNet dependencies
RUN pip install --no-cache-dir \
    runpod \
    transformers \
    Pillow \
    "numpy<2" \
    huggingface_hub \
    timm \
    einops \
    kornia \
    scipy \
    scikit-image \
    accelerate \
    opencv-python-headless \
    tqdm \
    prettytable

# Pre-download BiRefNet model weights during build (faster cold starts)
RUN python -c "from transformers import AutoModelForImageSegmentation; AutoModelForImageSegmentation.from_pretrained('ZhengPeng7/BiRefNet', trust_remote_code=True)"

# Copy handler
COPY rp_handler.py /app/rp_handler.py

CMD ["python", "/app/rp_handler.py"]
