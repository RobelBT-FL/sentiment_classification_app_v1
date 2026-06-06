import logging

logger = logging.getLogger(__name__)

async def on_shutdown():
    logger.info("🛑 Application shutdown")
