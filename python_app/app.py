from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import os
from handlers.accounting_message_handler import router as accounting_router
from handlers.pos_message_handler import router as pos_router


app = FastAPI(title="Python n8n Integration API")

N8N_URL = os.getenv('N8N_INTERNAL_URL', 'Not Set')

app.include_router(accounting_router)
app.include_router(pos_router)


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

