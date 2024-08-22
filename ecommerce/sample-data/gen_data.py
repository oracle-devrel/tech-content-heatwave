import random

def generate_name():
    first_names = ["John", "Jane", "David", "Emily", "Michael", "Sarah", "Chris", "Anna", "James", "Emma"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"]
    return f"{random.choice(first_names)} {random.choice(last_names)}"

languages = ["en", "fr", "de", "es", "it"]
language_names = {
    "en": "English",
    "fr": "French",
    "de": "German",
    "es": "Spanish",
    "it": "Italian"
}

products = [
    ("Shirt", 29.99, "Clothing"),
    ("Top", 39.99, "Clothing"),
    ("Pants", 49.99, "Clothing"),
    ("Shorts", 34.99, "Clothing"),
    ("Coffee Mug", 8.99, "Kitchenware"),
    ("Baseball Cap", 17.99, "Accessories"),
    ("Leather Jacket", 129.99, "Clothing"),
    ("Knit Sweater", 59.99, "Clothing"),
    ("Winter Scarf", 24.99, "Accessories"),
    ("Touchscreen Gloves", 19.99, "Accessories")
]

customers = [
    generate_name() for _ in range(20)
]

product_details = [
    (i+1, "en", random.choice(["S", "M", "L", "XL", "XXL"]), random.choice(["Cotton", "Polyester", "Denim", "Wool", "Leather"]), random.choice(["Machine wash cold", "Hand wash only", "Dry clean only", "Do not bleach"])) for i in range(10)
]

product_descriptions = [
    (i+1, "en", f"High-quality {products[i][0]} made from {random.choice(['soft', 'durable', 'breathable', 'luxurious'])} {random.choice(['cotton', 'wool', 'leather', 'polyester'])}. Perfect for {random.choice(['everyday wear', 'casual outings', 'weekend adventures', 'special occasions'])}. Available in multiple colors and sizes.") for i in range(10)
]

reviews = [
    (i+1, random.randint(1, 20), random.randint(1, 5), "en", f"Great {products[i][0]}! Fits perfectly and looks amazing.") for i in range(10)
]

orders = [
    (random.randint(1, 20), f"2024-05-{random.randint(1, 28):02d}", round(random.uniform(50, 200), 2)) for _ in range(100)
]

order_items = [
    (i+1, random.randint(1, 10), random.randint(1, 5), round(random.uniform(10, 100), 2)) for i in range(100)
]

# Generate SQL for languages
languages_sql = "INSERT INTO languages (language_code, language_name) VALUES\n"
languages_sql += ",\n".join([f"('{code}', '{name}')" for code, name in language_names.items()]) + ";\n\n"

# Generate SQL for products
products_sql = "INSERT INTO products (name, price, category) VALUES\n"
products_sql += ",\n".join([f"('{name}', {price}, '{category}')" for name, price, category in products]) + ";\n\n"

# Generate SQL for product details
product_details_sql = "INSERT INTO productdetails (product_id, language_code, size, material, washing_instructions) VALUES\n"
product_details_sql += ",\n".join([f"({product_id}, '{lang_code}', '{size}', '{material}', '{washing_instructions}')" for product_id, lang_code, size, material, washing_instructions in product_details]) + ";\n\n"

# Generate SQL for product descriptions
product_descriptions_sql = "INSERT INTO productdescriptions (product_id, language_code, description) VALUES\n"
product_descriptions_sql += ",\n".join([f"({product_id}, '{lang_code}', '{desc}')" for product_id, lang_code, desc in product_descriptions]) + ";\n\n"

# Generate SQL for customers
customers_sql = "INSERT INTO customers (first_name, last_name) VALUES\n"
customers_sql += ",\n".join([f"('{name.split()[0]}', '{name.split()[1]}')" for name in customers]) + ";\n\n"

# Generate SQL for reviews
reviews_sql = "INSERT INTO reviews (product_id, customer_id, rating, language_code, review_text) VALUES\n"
reviews_sql += ",\n".join([f"({product_id}, {customer_id}, {rating}, '{lang_code}', '{review}')" for product_id, customer_id, rating, lang_code, review in reviews]) + ";\n\n"

# Generate SQL for orders
orders_sql = "INSERT INTO orders (customer_id, order_date, total) VALUES\n"
orders_sql += ",\n".join([f"({customer_id}, '{order_date}', {total})" for customer_id, order_date, total in orders]) + ";\n\n"

# Generate SQL for order items
order_items_sql = "INSERT INTO orderitems (order_id, product_id, quantity, price) VALUES\n"
order_items_sql += ",\n".join([f"({order_id}, {product_id}, {quantity}, {price})" for order_id, product_id, quantity, price in order_items]) + ";\n\n"

# Write SQL statements to a file
file = "data.sql"
with open(file, "w") as f:
    f.write(languages_sql)
    f.write(products_sql)
    f.write(product_details_sql)
    f.write(product_descriptions_sql)
    f.write(customers_sql)
    f.write(reviews_sql)
    f.write(orders_sql)
    f.write(order_items_sql)

print(f"SQL statements have been written to '{file}'")

