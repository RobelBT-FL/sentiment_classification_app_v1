# backend/app/api/deps/__init__.py
"""
Shared dependencies for API endpoints.

These functions are used with FastAPI's Depends(...)
to inject common objects like:
- settings
- model
- services
- auth helpers
- vector DB clients
"""
