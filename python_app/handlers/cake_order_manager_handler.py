import os
import logging
import httpx
from fastapi import APIRouter, HTTPException, Request
from utils.cake_order_validator import validate_cake_order

# 1. Setup Logger
# This creates a logger specific to this module
logger = logging.getLogger("cake_order_service")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)

N8N_URL = os.getenv('N8N_INTERNAL_URL', '')
GET_CAKE_ORDER_REVIEW_WEBHOOK = f"{N8N_URL}webhook/cakeOrder/review"
GET_CAKE_ORDER_UPCOMING_WEBHOOK = f"{N8N_URL}webhook/cakeOrder/upcoming"
GET_CAKE_ORDER_HISTORIC_WEBHOOK = f"{N8N_URL}webhook/cakeOrder/historic"
PERFORM_REVIEW_WEBHOOK = f"{N8N_URL}webhook/cakeOrder/performReview"
GET_CAKE_ORDER_CHAT_LOGS_WEBHOOK = f"{N8N_URL}webhook/cakeOrder/chatLogs"
GET_CAKE_ORDER_CHAT_SESSIONS_WEBHOOK = f"{N8N_URL}webhook/cakeOrder/chatSessions"
SEND_CHAT_MESSAGE_WEBHOOK = f"{N8N_URL}webhook/cakeOrder/sendChatMessage"


router = APIRouter(
    prefix="/api/cakeOrder",
    tags=["cakeOrder"]
)

async def get(request: Request, url):
    logger.info("Received request for {url}}")
    logger.info(f"Request Host: {request.client}")

    params = request.query_params
    
    async with httpx.AsyncClient() as client:
        try:
            logger.info(f"Calling n8n webhook at: {url}")
            
            # Make the call to n8n
            response = await client.get(url, params=params)
            
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
            logger.exception("Unexpected error in get_ledger endpoint")
            raise HTTPException(status_code=500, detail="Internal Server Error")

@router.get("/review")
async def get_review_orders(request: Request):
    # Fixed variable name
    return await get(request, GET_CAKE_ORDER_REVIEW_WEBHOOK)

@router.get("/upcoming")
async def get_upcoming_orders(request: Request):
    # Fixed variable name
    return await get(request, GET_CAKE_ORDER_UPCOMING_WEBHOOK)

@router.get("/historic")
async def get_historic_orders(request: Request):
    # Fixed variable name
    return await get(request, GET_CAKE_ORDER_HISTORIC_WEBHOOK)

@router.get("/chatLogs")
async def get_chat_logs(request: Request):
    # Fixed variable name
    return await get(request, GET_CAKE_ORDER_CHAT_LOGS_WEBHOOK)

@router.get("/chatSessions")
async def get_chat_sessions(request: Request):
    # Fixed variable name
    return await get(request, GET_CAKE_ORDER_CHAT_SESSIONS_WEBHOOK)

# Inside your get/post helper functions, fix the logger:
# logger.info(f"Received request for {url}"

async def post(request: Request, url):
    logger.info("Received request for {url}}")
    logger.info(f"Request Host: {request.client}")
    async with httpx.AsyncClient() as client:
        try:
            logger.info(f"Capturing request Body")
            body = await request.json()

            logger.info(f"Calling n8n webhook at: {url}")
            
            # Make the call to n8n
            response = await client.post(url, json=body)
            
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
            logger.exception("Unexpected error in get_ledger endpoint")
            raise HTTPException(status_code=500, detail="Internal Server Error")

@router.post("/performReview")
async def create_perform_review(request: Request):
    return await post(request, PERFORM_REVIEW_WEBHOOK)

@router.post("/sendChatMessage")
async def create_send_chat_message(request: Request):
    return await post(request, SEND_CHAT_MESSAGE_WEBHOOK)

@router.post("/validate")
async def validate_order(request: Request):
    try:
        body = await request.json()
        logger.info(f"Received request for order validation")
        logger.info(f"Body: {body}")
        old_selection = body.get("old_selection", {})
        new_extraction = body.get("new_extraction", {})
        config = body.get("config", {})
        logger.info(f"Config: {config}")    
        validation_result = validate_cake_order(old_selection, new_extraction, config)
        return validation_result
    except Exception as e:
        logger.error(f"Error validating cake order: {str(e)}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))



