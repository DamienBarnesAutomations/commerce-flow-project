import streamlit as st
from db.db_services import record_transaction

def render_cart(record_transaction):
    # Show persistent success message if the flag exists
    if st.session_state.get('checkout_success'):
        st.success("✅ Sale Recorded!")
        # Delete it so it doesn't show up again on the next click
        del st.session_state.checkout_success
        
    # 1. Cart-Specific CSS (Scoped to this component)
    st.markdown("""
        <style>
        /* Target the 'x' remove button in the cart columns */
        [data-testid="column"] button:has(div:contains("×")) {
            background: none !important;
            border: none !important;
            color: #888 !important;
            padding: 0px !important;
            font-weight: bold !important;
            font-size: 1.2rem !important;
            line-height: 1 !important;
            width: auto !important;
        }
        [data-testid="column"] button:has(div:contains("×")):hover {
            color: #ff4b4b !important;
            background: none !important;
        }

        /* Styling for the Checkout button specifically inside the cart */
        [data-testid="stVerticalBlockBordered"] button[kind="primary"] {
            margin-top: 10px;
        }
        
        /* Make the Clear button look like a link */
        button[key="clear_cart"] {
            background: none !important;
            border: none !important;
            padding: 0 !important;
            color: #ff4b4b !important;
            text-decoration: underline;
            font-size: 0.8rem;
            height: auto !important;
        }
        /* Scoped background for the cart column only */
        [data-testid="column"]:nth-child(2) [data-testid="stVerticalBlockBordered"] {
            background-color: #1e1e1e;
            border-radius: 12px;
        }
        </style>
        """, unsafe_allow_html=True)

    # 2. Cart Logic & UI
    with st.container(border=True):
        head_col, clear_col = st.columns([2, 1])
        with head_col:
            st.subheader("Order")
        with clear_col:
            if st.button("Clear", key="clear_cart"):
                st.session_state.cart = []
                st.rerun()
        
        if not st.session_state.cart:
            st.info("No items in cart.")
        else:
            total = 0
            with st.container(height=400, border=False):
                # We use a copy of the list for safe iteration during removal
                for idx, item in enumerate(st.session_state.cart):
                    c1, c2, c3 = st.columns([4, 2, 1])
                    c1.write(f"**{item['name']}**")
                    c2.write(f"€{item['price']:.2f}")
                    
                    # The 'x' Button
                    if c3.button("×", key=f"remove_{idx}"):
                        st.session_state.cart.pop(idx)
                        st.rerun()
                    
                    total += item['price']
            
            st.divider()
            st.subheader(f"Total: €{total:.2f}")
            
            if st.button("Checkout", type="primary", width='stretch'):
                if record_transaction(st.session_state.cart):
                    st.success("Sale Recorded!")
                    st.session_state.cart = []
                    st.session_state.checkout_success = True
                    st.rerun()
                else:
                    st.error("Database connection failed.")