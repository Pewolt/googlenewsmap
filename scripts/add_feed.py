#!/usr/bin/env python3

import sys
import logging
import requests
import xml.etree.ElementTree as ET
from db_connection import get_connection, return_connection
from dateutil import parser as date_parser

# Logging konfigurieren
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def parse_date(date_str):
    try:
        return date_parser.parse(date_str)
    except Exception as e:
        logger.error(f"Fehler beim Parsen des Datums '{date_str}': {e}")
        return None

def add_feeds_for_all_countries(topic_code, topic_name):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        if conn is None:
            logger.error("Keine Datenbankverbindung verfügbar")
            return

        conn.autocommit = True
        cursor = conn.cursor()

        # Thema abrufen oder hinzufügen
        cursor.execute("SELECT id FROM topics WHERE topic_name = %s", (topic_name,))
        topic = cursor.fetchone()
        if not topic:
            # Link zum Thema erstellen (ohne Ländercode)
            topic_link_template = f"https://news.google.com/rss/topics/{topic_code}?hl={{hl}}&gl={{gl}}&ceid={{ceid}}"
            cursor.execute("""
                INSERT INTO topics (topic_name, link)
                VALUES (%s, %s)
                RETURNING id
            """, (topic_name, topic_link_template))
            topic_id = cursor.fetchone()[0]
            logger.info(f"Thema '{topic_name}' hinzugefügt.")
        else:
            topic_id = topic[0]
            # Den gespeicherten Thema-Link abrufen
            cursor.execute("SELECT link FROM topics WHERE id = %s", (topic_id,))
            topic_link_template = cursor.fetchone()[0]

        # Alle Länder abrufen
        cursor.execute("SELECT id, iso_code FROM countries")
        countries = cursor.fetchall()

        # Länder priorisieren: DE und US zuerst
        priority_countries = [country for country in countries if country[1] in ['DE', 'US']]
        remaining_countries = [country for country in countries if country[1] not in ['DE', 'US']]

        # Länder neu anordnen
        ordered_countries = priority_countries + remaining_countries

        for country_id, iso_code in ordered_countries:
            # Feed-Link für das Land erstellen
            hl = iso_code.lower()
            gl = iso_code.upper()
            ceid = f"{gl}:{hl}"
            feed_url = topic_link_template.format(hl=hl, gl=gl, ceid=ceid)

            # Feed abrufen
            try:
                response = requests.get(feed_url)
                response.raise_for_status()
                root = ET.fromstring(response.content)

                # Titel, Sprache und Link aus dem Feed extrahieren
                channel = root.find('channel')
                title_element = channel.find('title')
                language_element = channel.find('language')
                link_element = channel.find('link')
                last_build_date_element = channel.find('lastBuildDate')

                feed_title = title_element.text if title_element is not None else None
                language = language_element.text if language_element is not None else iso_code
                last_build_date = parse_date(last_build_date_element.text) if last_build_date_element is not None else None

                # Query-Parameter aus dem Link extrahieren
                feed_link = link_element.text if link_element is not None else ''
                query_params = ''
                if '?' in feed_link:
                    query_params = feed_link.split('?', 1)[1]

                # Prüfen, ob der Feed bereits existiert
                cursor.execute("""
                    SELECT id FROM feeds WHERE query_params = %s AND topic_id = %s
                """, (query_params, topic_id))
                feed = cursor.fetchone()
                if not feed:
                    # Feed in die Datenbank einfügen
                    cursor.execute("""
                        INSERT INTO feeds (title, language, last_build_date, country_id, topic_id, query_params)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, (feed_title, language, last_build_date, country_id, topic_id, query_params))
                    logger.info(f"Feed für Land '{iso_code}' und Thema '{topic_name}' hinzugefügt.")
                else:
                    logger.info(f"Feed für Land '{iso_code}' und Thema '{topic_name}' existiert bereits mit denselben Query-Parametern. Übersprungen.")

            except Exception as e:
                logger.error(f"Fehler beim Abrufen oder Verarbeiten des Feeds für Land '{iso_code}': {e}")

    except Exception as e:
        logger.error(f"Fehler beim Hinzufügen der Feeds: {e}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            return_connection(conn)

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Verwendung: python add_feed.py <topic_code> <topic_name>")
        sys.exit(1)

    topic_code = sys.argv[1]
    topic_name = sys.argv[2]

    add_feeds_for_all_countries(topic_code, topic_name)
