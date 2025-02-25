import os
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Dict, Any
import json

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

def get_db_connection():
    """Create and return a database connection."""
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        cursor_factory=RealDictCursor,
    )
    return conn

def create_or_get_user(username: str) -> Dict[str, Any]:
    """Create or get a user from the database."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        # Check if the user already exists
        cur.execute("SELECT * FROM users WHERE username = %s", (username,))
        user = cur.fetchone()
        if not user:
            # Create a new user
            cur.execute(
                "INSERT INTO users (username) VALUES (%s) RETURNING *",
                (username,),
            )
            user = cur.fetchone()
            conn.commit()
        return user
    finally:
        cur.close()
        conn.close()

def save_request(user_id: int, input_data: Dict[str, Any]) -> Dict[str, Any]:
    """Save a request to the database."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO requests (user_id, input_data) VALUES (%s, %s) RETURNING *",
            (user_id, json.dumps(input_data)),
        )
        request = cur.fetchone()
        conn.commit()
        return request
    finally:
        cur.close()
        conn.close()

def save_response(request_id: int, output_data: Dict[str, Any]) -> Dict[str, Any]:
    """Save a response to the database."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO responses (request_id, output_data) VALUES (%s, %s) RETURNING *",
            (request_id, json.dumps(output_data)),
        )
        response = cur.fetchone()
        conn.commit()
        return response
    finally:
        cur.close()
        conn.close()
