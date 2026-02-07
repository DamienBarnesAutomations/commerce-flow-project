from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

import os
from handlers.accounting_message_handler import router as accounting_router
from handlers.pos_message_handler import router as pos_router
from handlers.telegram_admin_message_handler import router as telegram_admin_router


app = FastAPI(title="Python n8n Integration API")
N8N_URL = os.getenv('N8N_INTERNAL_URL', 'Not Set')
DOMAIN_OR_IP = os.getenv('DOMAIN_OR_IP', 'Not Set')

app.include_router(accounting_router)
app.include_router(pos_router)
app.include_router(telegram_admin_router)


origins = [
    DOMAIN_OR_IP,"https://api.telegram.org"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "FastAPI is running",
        "n8n_endpoint": N8N_URL
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# Global Error Handler (The modern way to do @handle_api_errors)
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"message": "An internal error occurred", "details": str(exc)},
    )

# Registering the "Blueprint"

