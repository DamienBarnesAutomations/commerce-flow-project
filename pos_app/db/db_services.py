import os
import logging
import psycopg2
from psycopg2 import pool, DatabaseError, OperationalError
from psycopg2.extras import RealDictCursor, execute_batch
from db import db_queries 

# --- Logging Configuration ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# --- Database Configuration ---
# Fetching from environment variables with defaults or None
DB_CONFIG = {
    "dbname": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASS"),
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432")
}

def get_db_connection():
    """
    Establishes and returns a connection to the PostgreSQL database.
    Raises OperationalError if the connection fails.
    """
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except OperationalError as e:
        logger.error(f"Could not connect to database: {e}")
        raise

def fetch_products():
    """
    Fetches all products from the database, sorted by name.
    Returns: List of dictionaries or an empty list if an error occurs.
    """
    query = db_queries.FETCH_ALL_PRODUCTS_QUERY
    
    try:
        # Using context managers ensures the connection and cursor close automatically
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(query)
                products = cur.fetchall()
                
                # Convert Decimal to float for JSON/Streamlit serialization
                for p in products:
                    p['price'] = float(p['price'])
                
                logger.info(f"Successfully fetched {len(products)} products.")
                return products
                
    except DatabaseError as e:
        logger.error(f"Database error while fetching products: {e}")
        return []
    except Exception as e:
        logger.error(f"Unexpected error in fetch_products: {e}")
        return []

def record_transaction(cart_items):
    """
    Records multiple items into the sales table using a single transaction.
    Uses execute_batch for better performance over large datasets.
    """
    if not cart_items:
        logger.warning("record_transaction called with an empty cart.")
        return False

    insert_query = db_queries.INSERT_NEW_SALES_QUERY
    
    # Prepare data tuple for execute_batch
    data = [(item['id'], 1, item['price']) for item in cart_items]

    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # execute_batch is more efficient than a python loop for multiple inserts
                execute_batch(cur, insert_query, data)
                conn.commit()
                
        logger.info(f"Successfully recorded transaction with {len(cart_items)} items.")
        return True

    except DatabaseError as e:
        logger.error(f"Database error during transaction: {e}")
        # Connection context manager handles rollback automatically on