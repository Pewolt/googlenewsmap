# db_connection.py

import psycopg2
from psycopg2 import pool
import logging
from logging_config import setup_logging
from dotenv import load_dotenv
import os

# Laden der Umgebungsvariablen
load_dotenv()

# Logging konfigurieren
setup_logging()
logger = logging.getLogger(__name__)

try:
    # Erstelle einen Connection Pool
    db_pool = psycopg2.pool.SimpleConnectionPool(
        1,  # Minimale Anzahl an Verbindungen
        10,  # Maximale Anzahl an Verbindungen
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT", "5433"),
        database=os.getenv("DB_NAME"),
        options="-c search_path=google_news"
    )
    if db_pool:
        logger.debug("Connection Pool erfolgreich erstellt")

except (Exception, psycopg2.DatabaseError) as error:
    logger.error(f"Fehler beim Erstellen des Connection Pools: {error}")
    db_pool = None

def get_connection():
    try:
        if db_pool:
            conn = db_pool.getconn()
            logger.debug("Verbindung aus dem Pool erhalten")
            return conn
        else:
            logger.error("Connection Pool ist nicht verfügbar")
            return None
    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f"Fehler beim Abrufen der Verbindung: {error}")
        return None

def return_connection(conn):
    try:
        if db_pool:
            db_pool.putconn(conn)
            logger.debug("Verbindung zurück in den Pool gegeben")
    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f"Fehler beim Zurückgeben der Verbindung: {error}")

def close_all_connections():
    try:
        if db_pool:
            db_pool.closeall()
            logger.debug("Alle Verbindungen im Pool geschlossen")
    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(f"Fehler beim Schließen der Verbindungen: {error}")
