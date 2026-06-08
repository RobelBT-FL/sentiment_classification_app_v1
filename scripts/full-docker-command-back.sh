# ============================
# 1. Build backend image
# ============================
docker build -f Dockerfile.localB -t backend-docker-sentiment .

# ============================
# 2. Stop old container (ignore errors if none)
# ============================
docker stop backend-container
docker rm backend-container

# ============================
# 3. Run backend container with dataset mounted
# ============================
docker run --name backend-container -p 8000:8000 ^
  -v C:\Users\robel\Robel_AI_ML_Projects\project_app\sentiment_classification_app_v1\data:/data ^
  backend-docker-sentiment

# ============================
# 4. Check running containers
# ============================
docker ps

# ============================
# 5. Enter container shell
# ============================
docker exec -it backend-container sh

# ============================
# 6. Verify dataset is mounted
# ============================
ls /data

# ============================
# 7. View backend logs
# ============================
docker logs backend-container

# ============================
# 8. Test backend API
# ============================
curl http://localhost:8000/health
curl http://localhost:8000/docs

# ============================
# 9. Remove unused containers/images
# ============================
docker system prune -a
