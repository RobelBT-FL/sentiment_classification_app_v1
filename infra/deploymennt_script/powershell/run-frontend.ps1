Write-Host "🔥 Building frontend image (no cache)..."

docker build --no-cache --pull `
    -f Dockerfile.localF `
    -t frontend-docker-sentiment `
    --build-arg NEXT_PUBLIC_API_URL=http://localhost:8000 `
    .

Write-Host "🔥 Running frontend container..."

docker stop frontend-container 2>$null
docker rm frontend-container 2>$null

docker run `
    --name frontend-container `
    -p 3000:3000 `
    frontend-docker-sentiment

Write-Host "✅ Frontend running at: http://localhost:3000"
