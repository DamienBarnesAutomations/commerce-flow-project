import logging
from functools import wraps
from flask import jsonify

logger = logging.getLogger(__name__)

def handle_api_errors(f):
    """
    Decorator to wrap API handler functions, catching exceptions
    and returning a standardized JSON error response.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except Exception as e:
            # Catch all unhandled exceptions (e.g., from DB connection issues)
            logger.exception("Unhandled API Error in handler: %s", e)
            return jsonify({
                "message": "An internal server error occurred.",
                "error": str(e)
            }), 500
    return decorated_function