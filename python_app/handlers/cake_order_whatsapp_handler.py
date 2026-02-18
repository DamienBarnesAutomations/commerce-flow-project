import os
import logging
import httpx
from fastapi import APIRouter, HTTPException, Request, Query, Response
from pydantic import BaseModel

logger = logging.getLogger("cake_order_whatsapp_service")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)

router = APIRouter(
    prefix="/api/cakeOrder/whatsapp",
    tags=["cakeOrder_whatsapp"]
)

# WhatsApp uses phone numbers as strings, not integer chat IDs
class WhatsAppMessage(BaseModel):
    phone_number: str
    text: str

# --- Configuration ---
N8N_URL = os.getenv('N8N_INTERNAL_URL', '')
WHATSAPP_N8N_WEBHOOK_URL = N8N_URL + "webhook/cakeOrder/receive/whatsapp"

# WhatsApp Business Cloud API Settings
CAKE_ORDER_WHATSAPP_BOT_TOKEN = os.getenv('CAKE_ORDER_WHATSAPP_BOT_TOKEN', '')
CAKE_ORDER_WHATSAPP_PHONE_NUMBER_ID = os.getenv('CAKE_ORDER_WHATSAPP_PHONE_NUMBER_ID', '') # Found in Meta Dashboard
VERIFY_TOKEN = os.getenv('WHATSAPP_VERIFY_TOKEN', 'my_secure_token') # Set by you

WHATSAPP_API_URL = f"https://graph.facebook.com/v18.0/{CAKE_ORDER_WHATSAPP_PHONE_NUMBER_ID}/messages"

@router.get("/receive")
async def verify_webhook(
    mode: str = Query(None, alias="hub.mode"),
    token: str = Query(None, alias="hub.verify_token"),
    challenge: str = Query(None, alias="hub.challenge")
):
    if mode == "subscribe" and token == VERIFY_TOKEN:
        logger.info("Webhook verified!")
        # Return the challenge as a plain string with a 200 OK status
        return Response(content=challenge, media_type="text/plain")
    
    logger.error(f"Verification failed. Expected {VERIFY_TOKEN} but got {token}")
    logger.error(f"Verification failed. Expected 'subscribe' but got {mode}")
    raise HTTPException(status_code=403, detail="Verification failed")

from fastapi import BackgroundTasks  # Add this import

@router.post("/receive")
async def receive(request: Request, background_tasks: BackgroundTasks):
    try:
        body = await request.json()
        logger.info(f"Incoming WhatsApp Payload: {body}")
        
        # Fire-and-forget n8n forwarding (non-blocking)
        background_tasks.add_task(forward_to_n8n, body)
        
        # Always return 200 OK immediately to WhatsApp
        return Response(content="", status_code=200)
    
    except Exception as e:
        logger.error(f"Error parsing WhatsApp webhook: {str(e)}", exc_info=True)
        # Still return 200 to avoid retries
        return Response(content="", status_code=200)

async def forward_to_n8n(body: dict):
    """Background task to forward to n8n"""
    try:
        async with httpx.AsyncClient() as client:
            logger.info(f"Forwarding to n8n: {WHATSAPP_N8N_WEBHOOK_URL}")
            response = await client.post(WHATSAPP_N8N_WEBHOOK_URL, json=body, timeout=10.0)
            logger.info(f"n8n Response: {response.status_code}")
    except Exception as e:
        logger.error(f"n8n forward failed: {str(e)}")


@router.post("/send")
async def send_to_whatsapp(message: WhatsAppMessage):
    """Sends a text message using the WhatsApp Cloud API"""
    
    headers = {
        "Authorization": f"Bearer {CAKE_ORDER_WHATSAPP_BOT_TOKEN}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "messaging_product": "whatsapp",
        "recipient_type": "individual",
        "to": message.phone_number,
        "type": "text",
        "text": {"body": message.text}
    }
    
    logger.info(f"Sending WhatsApp message to: {message.phone_number}")

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(WHATSAPP_API_URL, json=payload, headers=headers)
            response.raise_for_status()
            return {"status": "sent", "whatsapp_response": response.json()}

        except httpx.HTTPStatusError as e:
            logger.error(f"WhatsApp API error: {e.response.text}")
            raise HTTPException(status_code=e.response.status_code, detail=e.response.json())
        except Exception as e:
            logger.exception("Unexpected error")
            raise HTTPException(status_code=500, detail="Internal Server Error")