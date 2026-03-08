"""
BiRefNet Background Removal - RunPod Serverless Handler
Accepts base64 image input, returns base64 PNG with transparent background.
"""

import runpod
import torch
import numpy as np
from PIL import Image
from torchvision import transforms
import io
import base64

# ── Load model at cold start ──
print("Loading BiRefNet model...")
from transformers import AutoModelForImageSegmentation

# Load from local pre-downloaded weights (built into Docker image)
MODEL_PATH = "/app/birefnet_model"
model = AutoModelForImageSegmentation.from_pretrained(
    MODEL_PATH,
    trust_remote_code=True
)
model.eval()

device = "cuda" if torch.cuda.is_available() else "cpu"
model = model.to(device)

if device == "cuda":
    model = model.half()  # Use FP16 for faster inference on GPU

print(f"BiRefNet loaded on {device}")

# Preprocessing transform
transform = transforms.Compose([
    transforms.Resize((1024, 1024)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
])


def remove_background(image: Image.Image) -> Image.Image:
    """Remove background from PIL Image, return RGBA image with transparent BG."""
    original_size = image.size

    # Ensure RGB
    if image.mode != "RGB":
        image = image.convert("RGB")

    # Preprocess
    input_tensor = transform(image).unsqueeze(0).to(device)
    if device == "cuda":
        input_tensor = input_tensor.half()

    # Inference
    with torch.no_grad():
        preds = model(input_tensor)[-1].sigmoid()

    # Post-process mask
    pred = preds[0].squeeze().float()
    pred_pil = transforms.ToPILImage()(pred.cpu())
    mask = pred_pil.resize(original_size, Image.LANCZOS)

    # Apply mask as alpha channel
    result = image.convert("RGBA")
    result.putalpha(mask)

    return result


def handler(job):
    """RunPod serverless handler function."""
    job_input = job.get("input", {})

    # Get base64 image
    image_b64 = job_input.get("image") or job_input.get("source_image")
    if not image_b64:
        return {"error": "No 'image' field in input. Send base64-encoded image."}

    # Optional: return mask only
    return_mask = job_input.get("return_mask", False)

    try:
        # Decode input image
        image_bytes = base64.b64decode(image_b64)
        image = Image.open(io.BytesIO(image_bytes))

        # Remove background
        result = remove_background(image)

        if return_mask:
            # Return just the alpha mask as grayscale
            mask = result.getchannel("A")
            buf = io.BytesIO()
            mask.save(buf, format="PNG")
            output_b64 = base64.b64encode(buf.getvalue()).decode("utf-8")
        else:
            # Return full RGBA image
            buf = io.BytesIO()
            result.save(buf, format="PNG")
            output_b64 = base64.b64encode(buf.getvalue()).decode("utf-8")

        return {
            "image": output_b64,
            "width": result.size[0],
            "height": result.size[1],
            "format": "PNG",
            "has_transparency": True
        }

    except Exception as e:
        return {"error": str(e)}


runpod.serverless.start({"handler": handler})
