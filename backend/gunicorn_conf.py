# ============================
# Gunicorn Configuration
# ============================

import multiprocessing

# Bind to all interfaces on port 8000
bind = "0.0.0.0:8000"

# Number of worker processes
workers = multiprocessing.cpu_count() * 2 + 1

# Use Uvicorn worker class for FastAPI
worker_class = "uvicorn.workers.UvicornWorker"

# Max requests before recycling a worker (prevents memory leaks)
max_requests = 1000
max_requests_jitter = 50

# Worker timeout
timeout = 120

# Logging
accesslog = "-"
errorlog = "-"
loglevel = "info"
