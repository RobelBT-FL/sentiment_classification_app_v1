# ============================
# 1. Build frontend image
# ============================
docker build -f Dockerfile.localF -t frontend-docker-sentiment .

# ============================
# 2. Stop old container
# ============================
docker stop frontend-container
docker rm frontend-container

# ============================
# 3. Run frontend container
# ============================
docker run --name frontend-container -p 3000:3000 frontend-docker-sentiment

# ============================
# 4. View running containers
# ============================
docker ps

# ============================
# 5. View logs
# ============================
docker logs frontend-container

# ============================
# 6. Enter container shell
# ============================
docker exec -it frontend-container sh

# ============================
# 7. Clean unused images/containers
# ============================
docker system prune -a
