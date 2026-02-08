import logging
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
import bcrypt

# 1. Setup Logger
# This creates a logger specific to this module
logger = logging.getLogger("password_service")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)


router = APIRouter(
    prefix="/api/password",
    tags=["pos"]
)

class HashRequest(BaseModel):
    password: str

class VerifyRequest(BaseModel):
    password: str
    stored_hash: str

@router.post("/hash")
async def hash_password(request: HashRequest):
    # Hash with 12 rounds (good balance of security/speed)
    hashed = bcrypt.hashpw(request.password.encode(), bcrypt.gensalt(rounds=12))
    return {"hashed_password": hashed.decode('utf-8')}

@router.post("/verify")
async def verify_password(request: VerifyRequest):
    # Expect body: {"password": "plain", "stored_hash": "$2b$12$..."} 
    stored_hash = request.stored_hash  # Add to model
    return {"valid": bcrypt.checkpw(request.password.encode(), stored_hash.encode())}


