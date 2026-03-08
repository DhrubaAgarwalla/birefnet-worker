# BiRefNet Background Removal - RunPod Serverless Worker

State-of-the-art background removal using [BiRefNet](https://github.com/ZhengPeng7/BiRefNet) (Bilateral Reference Network).

## Deploy to RunPod

### Option A: Deploy from GitHub (Recommended)
1. Push this folder to a **GitHub repo**
2. Go to [RunPod Console → Serverless](https://www.runpod.io/console/serverless)
3. Click **"New Endpoint"**
4. Select **"Deploy from GitHub"**
5. Connect your GitHub account and select the repo
6. Set the Dockerfile path to `Dockerfile`
7. Configure:
   - **GPU**: L4 or RTX A5000 (24GB+ VRAM recommended)
   - **Max Workers**: 3
   - **Idle Timeout**: 5s
   - **Flex Workers**: Yes (scales to zero)
8. Click **Deploy**

### Option B: Build Docker image manually
```bash
docker build -t birefnet-worker .
docker tag birefnet-worker your-dockerhub/birefnet-worker:latest
docker push your-dockerhub/birefnet-worker:latest
```
Then use the Docker image URL when creating the endpoint in RunPod.

## API Usage

### Request
```json
POST https://api.runpod.ai/v2/{ENDPOINT_ID}/run
Headers: { "Authorization": "Bearer YOUR_API_KEY" }

{
  "input": {
    "image": "<base64 encoded image>",
    "return_mask": false
  }
}
```

### Response (poll status)
```json
GET https://api.runpod.ai/v2/{ENDPOINT_ID}/status/{JOB_ID}

{
  "status": "COMPLETED",
  "output": {
    "image": "<base64 PNG with transparent background>",
    "width": 1024,
    "height": 1024,
    "format": "PNG",
    "has_transparency": true
  }
}
```

### Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image` | string | required | Base64 encoded input image |
| `return_mask` | bool | false | If true, returns only the alpha mask |

## Cost
- ~1-3 seconds per image on L4/A5000
- ~$0.0003-$0.0006 per image
