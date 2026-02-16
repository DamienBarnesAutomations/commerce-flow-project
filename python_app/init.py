import os
import logging
import requests

TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN');
TELEGRAM_WEBHOOK_URL = os.getenv('TELEGRAM_WEBHOOK_URL');

CAKE_ORDER_TELEGRAM_BOT_TOKEN = os.getenv('CAKE_ORDER_TELEGRAM_BOT_TOKEN');
CAKE_ORDER_TELEGRAM_WEBHOOK_URL = os.getenv('CAKE_ORDER_TELEGRAM_WEBHOOK_URL');

# 1. Setup Logging Configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("telegram_setup.log"), # Saves to a file
        logging.StreamHandler()                    # Also prints to terminal
    ]
)
logger = logging.getLogger(__name__)

def set_webhook(token, webhook_url, bot_name="Bot"):
    """Attempts to set a Telegram webhook and logs the outcome."""
    if not token or not webhook_url:
        logger.warning(f"Skipping {bot_name}: Missing token or URL.")
        return

    url = f"https://api.telegram.org/bot{token}/setWebhook"
    payload = {'url': webhook_url}

    logger.info(f"Setting {bot_name} webhook to: {webhook_url}")
    
    try:
        response = requests.post(url, data=payload, timeout=10)
        response.raise_for_status()
        
        result = response.json()
        if result.get("ok"):
            logger.info(f"SUCCESS ({bot_name}): {result.get('description')}")
        else:
            logger.error(f"FAILED ({bot_name}): {result.get('description')}")
            
    except requests.exceptions.RequestException as e:
        logger.error(f"CRITICAL ERROR ({bot_name}): Could not connect to Telegram API. Details: {e}")

def init():
    set_webhook(TELEGRAM_BOT_TOKEN, TELEGRAM_WEBHOOK_URL, 'Primary Bot')
    set_webhook(CAKE_ORDER_TELEGRAM_BOT_TOKEN, CAKE_ORDER_TELEGRAM_WEBHOOK_URL, "Cake Order Bot")