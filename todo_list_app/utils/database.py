import psycopg2

HOST = "localhost" # change if not on localserver
DB_NAME = "YOUR_DB_NAME"
USER = "YOUR_USERNAME" # use Admin if not changed
PASSWORD = "YOUR_DB_PASS"
PORT = YOUR_DB_PORT

def create_connection():
    try:
        conn = psycopg2.connect(
            host=HOST,
            database=DB_NAME,
            user=USER,
            password=PASSWORD,
            port=PORT
        )
        return conn
    except (psycopg2.Error) as error:
        print("Error while connecting to PostgreSQL", error)
        return psycopg2.connect(
            host=HOST,
            database=DB_NAME,
            user=USER,
            password=PASSWORD,
            port=PORT
        )

conn = create_connection()
cur = conn.cursor()
Error = psycopg2.Error
