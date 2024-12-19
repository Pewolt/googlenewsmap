#!/usr/bin/env python3

import logging
import requests
import xml.etree.ElementTree as ET
from dateutil import parser as date_parser
from db_connection import get_connection, return_connection
from typing import Optional, Tuple, List

# Logging konfigurieren
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger()

def parse_date(date_str: Optional[str]):
    if not date_str:
        return None
    try:
        return date_parser.parse(date_str)
    except Exception as e:
        logger.error(f"Date parsing error for '{date_str}': {e}")
        return None

def get_or_create_publisher(publisher_name: str, country_id: int) -> Optional[int]:
    if not publisher_name:
        return None

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # Überprüfen, ob der Publisher bereits existiert
        cursor.execute("SELECT id FROM publishers WHERE name = %s", (publisher_name,))
        publisher = cursor.fetchone()
        if publisher:
            return publisher[0]

        # Publisher ohne geografische Daten einfügen
        cursor.execute("""
            INSERT INTO publishers (name, country_id)
            VALUES (%s, %s)
            RETURNING id
        """, (publisher_name, country_id))
        
        conn.commit()
        return cursor.fetchone()[0]

    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Publisher creation error for '{publisher_name}': {e}")
        return None
    finally:
        if cursor:
            cursor.close()
        if conn:
            return_connection(conn)

def process_feed(feed):
    feed_id, title, language, last_build_date, country_id, topic_id, query_params = feed
    logger.info(f"Processing Feed ID {feed_id} - {title}")

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()

        # Thema-Link abrufen
        cursor.execute("SELECT link FROM topics WHERE id = %s", (topic_id,))
        topic_link = cursor.fetchone()[0]

        # Entfernen der Query-Parameter aus dem topic_link
        if '?' in topic_link:
            base_topic_link = topic_link.split('?', 1)[0]
        else:
            base_topic_link = topic_link

        # Feed-URL mit query_params erstellen
        feed_url = f"{base_topic_link}?{query_params}"

        # Feed abrufen
        response = requests.get(feed_url, timeout=10)
        response.raise_for_status()
        root = ET.fromstring(response.content)

        articles_batch: List[Tuple] = []

        consecutive_existing_articles = 0  # Zähler für aufeinanderfolgende vorhandene Artikel
        max_consecutive_existing = 10       # Schwellenwert für Abbruch

        # Artikel verarbeiten
        for item in root.findall(".//item"):
            pub_date_str = item.findtext("pubDate")
            pub_date = parse_date(pub_date_str)

            article_link = item.findtext("link")
            if not article_link:
                logger.warning("Kein Link im Artikel gefunden")
                continue

            article_title = item.findtext("title") or "Unbekannter Titel"

            # Prüfen, ob der Artikel bereits in der Datenbank vorhanden ist
            cursor.execute("""
                SELECT 1 FROM articles WHERE link = %s AND feed_id = %s
            """, (article_link, feed_id))
            if cursor.fetchone():
                consecutive_existing_articles += 1
                logger.info(f"Artikel bereits vorhanden: {article_title}")
                if consecutive_existing_articles >= max_consecutive_existing:
                    logger.info(f"{max_consecutive_existing} aufeinanderfolgende vorhandene Artikel gefunden. Abbruch der Verarbeitung.")
                    break
                continue
            else:
                consecutive_existing_articles = 0  # Zähler zurücksetzen

            # Publisher aus dem <source>-Element extrahieren
            source_element = item.find("source")
            publisher_name = source_element.text.strip() if source_element is not None else "Unbekannter Herausgeber"

            # Publisher abrufen oder erstellen
            publisher_id = get_or_create_publisher(publisher_name, country_id)
            
            articles_batch.append((article_title, article_link, pub_date, publisher_id, feed_id))

        # Artikel in die Datenbank einfügen
        if articles_batch:
            cursor.executemany("""
                INSERT INTO articles 
                (title, link, pub_date, publisher_id, feed_id)
                VALUES (%s, %s, %s, %s, %s)
            """, articles_batch)
            conn.commit()
            logger.info(f"Inserted {len(articles_batch)} new articles for feed {feed_id}")
        else:
            logger.info(f"No new articles to process for feed {feed_id}")

    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Feed processing error for '{title}': {e}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            return_connection(conn)

def main():
    logger.info("Starting feed parsing script")

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # Alle Feeds abrufen
        cursor.execute("""
            SELECT id, title, language, last_build_date, country_id, topic_id, query_params
            FROM feeds
            ORDER BY topic_id DESC, country_id ASC
        """)
        feeds = cursor.fetchall()
        logger.info(f"Feeds to process: {len(feeds)}")

    except Exception as e:
        logger.error(f"Error fetching feeds: {e}")
        return
    finally:
        if cursor:
            cursor.close()
        if conn:
            return_connection(conn)

    # Feeds verarbeiten
    for feed in feeds:
        process_feed(feed)

    logger.info("Feed parsing script completed")

if __name__ == '__main__':
    main()
