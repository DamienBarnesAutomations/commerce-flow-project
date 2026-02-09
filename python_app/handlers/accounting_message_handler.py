import os
import logging
import httpx
from fastapi import APIRouter, HTTPException, Request

# 1. Setup Logger
# This creates a logger specific to this module
logger = logging.getLogger("accounting_service")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)

N8N_URL = os.getenv('N8N_INTERNAL_URL', '')
GET_GENERAL_LEDGER_WEBHOOK = f"{N8N_URL}webhook/accounting/ledger"
GET_ACCOUNTS_WEBHOOK = f"{N8N_URL}webhook/accounting/accounts"
GET_JOURNAL_ENTRIES_WEBHOOK = f"{N8N_URL}webhook/accounting/journalEntries"
GET_TRIAL_BALANCE_WEBHOOK = f"{N8N_URL}webhook/accounting/trialBalance"
GET_CATEGORIES_WEBHOOK = f"{N8N_URL}webhook/accounting/categories"
GET_BALANCE_SHEET_WEBHOOK = f"{N8N_URL}webhook/accounting/balanceSheet"
GET_PROFIT_AND_LOSS_WEBHOOK = f"{N8N_URL}webhook/accounting/profitAndLoss"
POST_JOURNAL_ENTRIES_WEBHOOK =f"{N8N_URL}webhook/accounting/journalEntry"
GET_INCOME_REPORT_WEBHOOK =f"{N8N_URL}webhook/accounting/incomeReport"
GET_EXPENSE_REPORT_WEBHOOK =f"{N8N_URL}webhook/accounting/expenseReport"
CREATE_ACCOUNT_WEBHOOK =f"{N8N_URL}webhook/accounting/createAccount"


router = APIRouter(
    prefix="/api/accounting",
    tags=["Accounting"]
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

@router.get("/ledger")
async def get_ledger(request: Request):
    return await get(request, GET_GENERAL_LEDGER_WEBHOOK)

@router.get("/accounts")
async def get_accounts(request: Request):
    return await get(request, GET_ACCOUNTS_WEBHOOK)

@router.get("/journalEntries")
async def get_journal_entries(request: Request):
    return await get(request, GET_JOURNAL_ENTRIES_WEBHOOK)

@router.get("/trialBalance")
async def get_trial_balance(request: Request):
    return await get(request, GET_TRIAL_BALANCE_WEBHOOK)

@router.get("/categories")
async def get_categories(request: Request):
    return await get(request, GET_CATEGORIES_WEBHOOK)

@router.get("/balanceSheet")
async def get_balance_sheet(request: Request):
    return await get(request, GET_BALANCE_SHEET_WEBHOOK)

@router.get("/profitAndLoss")
async def get_profit_and_loss(request: Request):
    return await get(request, GET_PROFIT_AND_LOSS_WEBHOOK)

@router.get("/incomeReport")
async def get_income_report(request: Request):
    return await get(request, GET_INCOME_REPORT_WEBHOOK)

@router.get("/expenseReport")
async def get_expense_report(request: Request):
    return await get(request, GET_EXPENSE_REPORT_WEBHOOK)

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


@router.post("/journalEntry")
async def create_journal_entry(request: Request):
    return await post(request, POST_JOURNAL_ENTRIES_WEBHOOK)

@router.post("/createAccount")
async def create_account(request: Request):
    return await post(request, CREATE_ACCOUNT_WEBHOOK)

