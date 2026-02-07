import os
import logging
import httpx
from fastapi import APIRouter, HTTPException, Request

# 1. Setup Logger
# This creates a logger specific to this module
logger = logging.getLogger("telegram_admin_service")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)

router = APIRouter(
    prefix="/api/telegram/admin",
    tags=["Telegram_Admin"]
)

# --- Configuration ---
N8N_URL = os.getenv('N8N_INTERNAL_URL', '')
TELEGRAM_N8N_WEBHOOK_URL = N8N_URL +"webhook/admin/telegram/receive"

TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN', '')
TELEGRAM_API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"

@router.api_route("/receive",
methods=["GET", "POST"])
async def receive(request: Request):
    if request.method =="GET":
        return {"status": "Reachable"}

    logger.info("Received request for {TELEGRAM_N8N_WEBHOOK_URL}}")
    logger.info(f"Request Host: {request.client}")
    async with httpx.AsyncClient() as client:
        try:
            logger.info(f"Capturing request Body")
            body = await request.json()

            logger.info(f"Calling n8n webhook at: {TELEGRAM_N8N_WEBHOOK_URL}")
            
            # Make the call to n8n
            response = await client.post(TELEGRAM_N8N_WEBHOOK_URL, json=body)
            
            # Log response status
            logger.info(f"n8n responded with status: {response.status_code}")
            
            # Raise an error if the n8n workflow returned a 4xx or 5xx
            response.raise_for_status()

            n8n_data = response.json()
            logger.info("Successfully retrieved and parsed data from n8n")
            
            await respond(n8n_data)
            return n8n_data

        except httpx.HTTPStatusError as e:
            # Log specific HTTP errors from n8n (e.g., 404, 500)
            logger.error(
                f"HTTP error occurred while calling n8n: {e.response.status_code} - {e.response.text}"
            )
            raise HTTPException(status_code=e.response.status_code, detail="n8n service error")
            
        except httpx.RequestError as e:
            # Log network-level errors (e.g., DNS failure, connection timeout)
            logger.error(f"Network error while connecting to n8n: {str(e)}")
            raise HTTPException(status_code=503, detail="Could not reach n8n service")
            
        except Exception as e:
            # Catch-all for unexpected issues
            logger.exception(f"Unexpected error in {TELEGRAM_N8N_WEBHOOK_URL} endpoint")
            raise HTTPException(status_code=500, detail="Internal Server Error")

async def respond(n8n_data):
    logger.info(f"Response from webhook: {n8n_data[0]}")
    await send_to_telegram(n8n_data[0]["user_id"], n8n_data[0]["response_message"])

async def send_to_telegram(chat_id: int, text: str):
    """
    Endpoint for n8n to call when it wants to send a message back to the user.
    """

    logger.info(f"Send telegram url: {TELEGRAM_API_URL}")
    url = f"{TELEGRAM_API_URL}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "HTML"
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=payload)
        if response.status_code != 200:
            raise HTTPException(status_code=400, detail="Failed to send message to Telegram")
            
    return {"status": "sent"}
