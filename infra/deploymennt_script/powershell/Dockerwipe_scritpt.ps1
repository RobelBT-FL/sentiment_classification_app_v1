Write-Host "🔥 Wiping ALL Docker resources..."

# Stop all containers
docker stop $(docker ps -aq) 2>$null

# Remove all containers
docker rm $(docker ps -aq) 2>$null

# Remove all images
docker rmi -f $(docker images -aq) 2>$null

# Remove all volumes
docker volume rm $(docker volume ls -q) 2>$null

# Remove all custom networks (keep default ones)
$networks = docker network ls -q | Select-String -NotMatch "bridge|host|none"
if ($networks) {
    docker network rm $networks 2>$null
}

# Remove build cache
docker builder prune -a -f

# Final prune
docker system prune -a --volumes -f

Write-Host "✅ Docker fully wiped!"
