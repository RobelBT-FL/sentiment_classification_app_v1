###############################################
# 0. FULL DOCKER CLEAN (fresh start)
###############################################

# Stop all running containers
docker stop $(docker ps -aq) 2>$null

# Remove all containers
docker rm $(docker ps -aq) 2>$null

# Remove all images
docker rmi -f $(docker images -aq) 2>$null

# Remove all volumes
docker volume rm $(docker volume ls -q) 2>$null

# Remove all user-created networks (keep default ones)
docker network rm $(docker network ls -q | Select-String -NotMatch "bridge|host|none") 2>$null

# Remove all build cache
docker builder prune -a -f

# Final prune
docker system prune -a --volumes -f



###############################################
# 1. CREATE DOCKER NETWORK
###############################################

docker network create sentiment-net



###############################################
# 2. BACKEND — BUILD IMAGE
###############################################

# Run this inside: sentiment_classification_app_v1/backend
docker build -t backend-docker-sentiment .



###############################################
# 3. BACKEND — RUN CONTAINER
###############################################

docker run --name backend `
  --network sentiment-net `
  -p 8000:8000 `
  -v C:\Users\robel\Robel_AI_ML_Projects\project_app\sentiment_classification_app_v1\data:/data `
  backend-docker-sentiment



###############################################
# 4. FRONTEND — BUILD IMAGE
###############################################

# Run this inside: sentiment_classification_app_v1/frontend-next
docker build --no-cache `
  -f Dockerfile.localF `
  -t frontend-docker-sentiment `
  --build-arg NEXT_PUBLIC_API_URL=http://localhost:8000 .



###############################################
# 5. FRONTEND — RUN CONTAINER
###############################################

docker run --name frontend-container `
  --network sentiment-net `
  -p 3000:3000 `
  frontend-docker-sentiment



###############################################
# 6. VERIFY DOCKER NETWORK (optional)
###############################################

docker inspect frontend-container --format='{{json .NetworkSettings.Networks}}'
docker inspect backend --format='{{json .NetworkSettings.Networks}}'

# Test DNS inside Docker
docker exec -it frontend-container ping backend



###############################################
# 7. VERIFY FRONTEND ENV (browser console)
###############################################

# Open browser → DevTools → Console:
# window.__NEXT_DATA__
# Should show:
# env: { NEXT_PUBLIC_API_URL: "http://localhost:8000" }
###############################################
