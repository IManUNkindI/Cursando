import psycopg2

conn = psycopg2.connect(
    host="10.0.218.88",
    database="factoryio",
    user="postgres",
    password="1943",
    port=5432
)

print("Conexión exitosa")

conn.close()
