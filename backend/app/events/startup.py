import logging

logger = logging.getLogger(__name__)

async def on_startup():
    logger.info("🚀 Application startup")
