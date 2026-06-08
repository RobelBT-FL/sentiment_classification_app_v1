# ============================
# 1. Start everything
# ============================
docker-compose up --build

# ============================
# 2. Start in background
# ============================
docker-compose up -d

# ============================
# 3. Stop everything
# ============================
docker-compose down

# ============================
# 4. View logs (all services)
# ============================
docker-compose logs -f

# ============================
# 5. View logs (backend only)
# ============================
docker-compose logs -f backend

# ============================
# 6. Enter backend container
# ============================
docker exec -it backend-container sh

# ============================
# 7. Enter frontend container
# ============================
docker exec -it frontend-container sh

# ============================
# 8. Rebuild everything clean
# ============================
docker-compose down
docker-compose build --no-cache
docker-compose up
