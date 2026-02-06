import os
import logging
import httpx
from fastapi import APIRouter, HTTPException, Request

# 1. Setup Logger
# This creates a logger specific to this module
logger = logging.getLogger("pos_service")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)

N8N_URL = os.getenv('N8N_INTERNAL_URL', '')
GET_PRODUCTS_WEBHOOK = f"{N8N_URL}webhook/pos/products"
GET_DAILY_SALES_WEBHOOK = f"{N8N_URL}webhook/pos/dailyTotalSales"
RECORD_SALES_WEBHOOK = f"{N8N_URL}webhook/pos/recordSales"

router = APIRouter(
    prefix="/api/pos",
    tags=["pos"]
)

async def get(request: Request, url):
    logger.info("Received request for {url}}")
    logger.info(f"Request Host: {request.client}")
    async with httpx.AsyncClient() as client:
        try:
            logger.info(f"Calling n8n webhook at: {url}")
            
            # Make the call to n8n
            response = await client.get(url)
            
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



@router.get("/products")
async def get_products(request: Request):
    return await get(request, GET_PRODUCTS_WEBHOOK)
    

@router.get("/dailyTotalSales")
async def get_daily_sales(request: Request):
    return await get(request, GET_DAILY_SALES_WEBHOOK)


@router.post("/recordSales")
async def record_sales(request: Request):
    logger.info("Received request for {url}}")
    logger.info(f"Request Host: {request.client}")
    async with httpx.AsyncClient() as client:
        try:
            logger.info(f"Capturing request Body")
            body = await request.json()

            logger.info(f"Calling n8n webhook at: {RECORD_SALES_WEBHOOK}")
            
            # Make the call to n8n
            response = await client.post(RECORD_SALES_WEBHOOK, json=body)
            
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
