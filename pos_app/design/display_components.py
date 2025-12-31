import os
import streamlit as st
IMAGE_BASE_URL = os.getenv("IMAGE_BASE_URL")



def generate_product_component2(product, add_to_cart):
    with st.container(border=True):
        st.image(f"{IMAGE_BASE_URL}{product['img_url']}", width='stretch')
        col_name, col_price = st.columns([3, 1], gap="small")
    
        with col_name:
            st.markdown(f"**{product['name']}**")
        with col_price:
            st.write(f"${float(product['price']):.2f}")
                
    # Callback pattern is cleaner than 'if st.button' inside loops
        st.button("Add", key=f"btn_{product['id']}", 
            on_click=add_to_cart, 
            args=(product['id'], product['name'], product['price']))

def generate_product_component(product, add_to_cart):
    # 1. The Image (Top of card)
    st.image(f"{IMAGE_BASE_URL}{product['img_url']}", width='stretch')
    
    # 2. The Full-Width Clickable Base
    # We combine Name and Price into the button label using a newline or pipe
    button_label = f"{product['name']} — €{float(product['price']):.2f}"
    
    st.button(
        button_label, 
        key=f"tile_{product['id']}", 
        on_click=add_to_cart, 
        args=(product['id'], product['name'], product['price']),
        width='stretch'
    )