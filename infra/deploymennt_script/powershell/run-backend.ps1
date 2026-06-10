Write-Host "🔥 Building backend image (no cache)..."

docker build --no-cache --pull `
    -f Dockerfile.localB `
    -t backend-docker-sentiment `
    .

Write-Host "🔥 Creating Docker network (if not exists)..."
docker network create sentiment-net 2>$null

Write-Host "🔥 Running backend container..."

docker stop backend 2>$null
docker rm backend 2>$null

docker run `
    --name backend `
    --network sentiment-net `
    -p 8000:8000 `
    -v "C:\Users\robel\Robel_AI_ML_Projects\project_app\sentiment_classification_app_v1\data:/app/data" `
    backend-docker-sentiment

Write-Host "✅ Backend running at: http://localhost:8000/docs"
