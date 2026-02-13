import os
import logging
import httpx
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel

# 1. Setup Logger
# This creates a logger specific to this module
logger = logging.getLogger("cake_order_telegram_service")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)

router = APIRouter(
    prefix="/api/cakeOrder/telegram",
    tags=["cakeOrder_telegram"]
)

class TelegramMessage(BaseModel):
    chat_id: int
    text: str

# --- Configuration ---
N8N_URL = os.getenv('N8N_INTERNAL_URL', '')
TELEGRAM_N8N_WEBHOOK_URL = N8N_URL +"webhook/cakeOrder/receive/telegram"

CAKE_ORDER_TELEGRAM_BOT_TOKEN = os.getenv('CAKE_ORDER_TELEGRAM_BOT_TOKEN', '')
TELEGRAM_API_URL = f"https://api.telegram.org/bot{CAKE_ORDER_TELEGRAM_BOT_TOKEN}"

@router.post("/receive")
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


@router.post("/send")
async def send_to_telegram(message: TelegramMessage):
    # Access data via message.chat_id and message.text
    chat_id = message.chat_id
    text = message.text
    url = f"{TELEGRAM_API_URL}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "HTML"
    }
    
    logger.info(f"Attempting to send Telegram message to chat_id: {chat_id}")

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, json=payload, timeout=10.0)
            
            # This will trigger the httpx.HTTPStatusError if response is 4xx or 5xx
            response.raise_for_status()
            
            logger.info(f"Successfully sent message to chat_id: {chat_id}")
            return {"status": "sent", "telegram_response": response.json()}

        except httpx.HTTPStatusError as e:
            # Handle specific Telegram errors (e.g., 403 Forbidden, 400 Bad Request)
            error_detail = e.response.json().get("description", "Unknown Telegram Error")
            logger.error(
                f"Telegram API error: {e.response.status_code} - {error_detail} "
                f"| Chat ID: {chat_id}"
            )
            raise HTTPException(
                status_code=e.response.status_code, 
                detail=f"Telegram API error: {error_detail}"
            )
            
        except httpx.RequestError as e:
            # Handle connection/network issues
            logger.error(f"Network error while connecting to Telegram: {str(e)}")
            raise HTTPException(
                status_code=503, 
                detail="Could not reach Telegram servers"
            )
            
        except Exception as e:
            # Catch-all for unexpected issues
            logger.exception(f"Unexpected error in send_to_telegram: {str(e)}")
            raise HTTPException(
                status_code=500, 
                detail="Internal Server Error"
            )
