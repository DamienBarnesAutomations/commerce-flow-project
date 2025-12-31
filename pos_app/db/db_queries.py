FETCH_ALL_PRODUCTS_QUERY = "SELECT id, name, price, img_url FROM products ORDER BY name ASC;"

INSERT_NEW_SALES_QUERY = "INSERT INTO sales (product_id, quantity, total_price) VALUES (%s, %s, %s);"