import streamlit as st
from datetime import datetime
from db.db_services import fetch_products, record_transaction
from design.display_components import generate_product_component
from design.display_cart import render_cart

# --- 1. PAGE CONFIG & THEME ---
st.set_page_config(page_title="Precious Place POS", layout="wide")

# Consolidated CSS: Handles Layout, Kiosk Mode, and Card Styling
st.markdown("""
    <style>
    /* 1. UI Clean-up: Hide Header, Footer, and Deploy Button */
    header, footer, div[data-testid="stStatusWidget"] { visibility: hidden; display: none; height: 0; }
    
    /* 2. Reclaim Space: Remove top padding */
    .block-container { padding-top: 1rem !important; padding-bottom: 0rem !important; }
    .stMainBlockContainer { padding-top: 0rem !important; }

    /* 3. Kiosk Mode: Disable Image Interactivity */
    button[title="Enlarge image"] { display: none; }
    [data-testid="stImage"] { pointer-events: none; }

    /* 4. Standardize Product Images */
    [data-testid="stImage"] img {
        height: 200px;
        object-fit: cover;
        border-radius: 8px 8px 0 0;
    }

    /* 5. Global Button Styling (Base for Product Tiles) */
    .stButton>button { 
        width: 100%; 
        border-radius: 5px; 
        height: 2em; 
        background-color: #2e7d32; 
        color: white; 
        font-weight: bold;
    }

    /* 6. Invisible Scrollbars */
    ::-webkit-scrollbar { display: none !important; }
    [data-testid="stVerticalBlock"] {
        scrollbar-width: none;
        -ms-overflow-style: none;
    }
    </style>
    """, unsafe_allow_html=True)

# --- 2. LOGIC & STATE ---
if 'cart' not in st.session_state:
    st.session_state.cart = []

def add_to_cart(p_id, name, price):
    st.session_state.cart.append({"id": p_id, "name": name, "price": float(price)})

# --- 4. MAIN INTERFACE ---
col_menu, col_cart = st.columns([3, 1], gap="large")

with col_menu:
    st.title("Precious Place POS")
    st.caption(f"Staff Portal | {datetime.now().strftime('%A, %d %B %Y')}")
    st.subheader("Products")
    products = fetch_products()
    
    # Render Grid
    with st.container(height=560, border=False):
        cols = st.columns(3)
        for idx, product in enumerate(products):
            with cols[idx % 3]:
                generate_product_component(product, add_to_cart)

with col_cart:
    render_cart(record_transaction)