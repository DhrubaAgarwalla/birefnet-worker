FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV HF_HOME=/app/hf_cache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3-pip \
    git \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set Python alias
RUN ln -sf /usr/bin/python3.11 /usr/bin/python
RUN python -m pip install --upgrade pip

WORKDIR /app

# Install PyTorch (>=2.5.0 required by BiRefNet)
RUN pip install --no-cache-dir \
    torch==2.5.1 \
    torchvision==0.20.1 \
    --index-url https://download.pytorch.org/whl/cu124

# Install BiRefNet dependencies (from official requirements.txt)
RUN pip install --no-cache-dir \
    "numpy<2" \
    opencv-python-headless \
    timm \
    scipy \
    scikit-image \
    kornia \
    einops \
    tqdm \
    prettytable \
    tabulate \
    "huggingface_hub>0.25" \
    accelerate \
    transformers

# Install RunPod SDK
RUN pip install --no-cache-dir runpod Pillow

# Pre-download BiRefNet model weights during build (faster cold starts)
# This downloads the model files + custom code from HuggingFace
RUN python -c "\
from huggingface_hub import snapshot_download; \
snapshot_download('ZhengPeng7/BiRefNet', local_dir='/app/birefnet_model')"

# Verify the model loads correctly during build
RUN python -c "\
from transformers import AutoModelForImageSegmentation; \
model = AutoModelForImageSegmentation.from_pretrained('/app/birefnet_model', trust_remote_code=True); \
print('BiRefNet model loaded successfully!')"

# Copy handler
COPY rp_handler.py /app/rp_handler.py

CMD ["python", "/app/rp_handler.py"]
