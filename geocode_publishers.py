#!/usr/bin/env python3

import logging
import requests
import time
from db_connection import get_connection, return_connection
from typing import Optional, Tuple

# Konfiguration
CONFIG = {
    'GEOCODE_RATE_LIMIT_DELAY': 1,  # Mindestens 1 Sekunde laut Nominatim-Nutzungsbedingungen
    'GEOCODE_MAX_RETRIES': 1,
    'REQUEST_TIMEOUT': 2  # Timeout für HTTP-Anfragen in Sekunden
}

# Logging konfigurieren
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger()

def geocode_location(location_name: str, country_code: str) -> Tuple[Optional[float], Optional[float], Optional[str], Optional[str], Optional[str]]:
    try:
        url = 'https://nominatim.openstreetmap.org/search'
        params = {
            'q': location_name,
            'countrycodes': country_code,
            'format': 'json',
            'limit': 1,
            'addressdetails': 1
        }
        headers = {'User-Agent': 'maptimes/1.0'}
        
        logger.debug(f"Sending geocoding request to {url} with params {params}")
        response = requests.get(url, params=params, headers=headers, timeout=CONFIG['REQUEST_TIMEOUT'])
        response.raise_for_status()
        logger.debug(f"Received response with status code {response.status_code}")
        data = response.json()
        logger.debug(f"Response JSON data: {data}")
        
        if data:
            first_result = data[0]
            logger.debug(f"First geocoding result for '{location_name}': {first_result}")
            latitude = float(first_result['lat'])
            longitude = float(first_result['lon'])
            address = first_result.get('address', {})
            logger.debug(f"Extracted address: {address}")
            
            country_name = address.get('country')
            country_code = address.get('country_code', '').upper()  # ISO 3166-1 Alpha-2 Code
            logger.debug(f"Extracted country name: {country_name}, country code: {country_code}")
            
            city = address.get('city') or address.get('town') or address.get('village')
            logger.debug(f"Extracted city: {city}")
            
            return latitude, longitude, country_name, city, country_code
        else:
            logger.warning(f"No geocoding results for '{location_name}'")
            return None, None, None, None, None
    except requests.exceptions.Timeout:
        logger.error(f"Timeout error for '{location_name}' after {CONFIG['REQUEST_TIMEOUT']} seconds.")
        return None, None, None, None, None
    except Exception as e:
        logger.error(f"Geocoding error for '{location_name}': {e}")
        return None, None, None, None, None

def geocode_with_rate_limit(location_name: str, iso_code: str) -> Optional[Tuple[float, float, str, str, str]]:
    for attempt in range(CONFIG['GEOCODE_MAX_RETRIES']):
        logger.debug(f"Geocoding '{location_name}', attempt {attempt + 1} of {CONFIG['GEOCODE_MAX_RETRIES']}")
        result = geocode_location(location_name, iso_code)
        if result and result[0] is not None:
            logger.debug(f"Successfully geocoded '{location_name}'")
            time.sleep(CONFIG['GEOCODE_RATE_LIMIT_DELAY'])
            return result
        else:
            logger.debug(f"Geocoding failed for '{location_name}', attempt {attempt + 1}")
            if attempt < CONFIG['GEOCODE_MAX_RETRIES'] - 1:
                logger.debug(f"Retrying geocode for '{location_name}' after delay")
                time.sleep(CONFIG['GEOCODE_RATE_LIMIT_DELAY'])
    logger.warning(f"All attempts to geocode '{location_name}' failed")
    return None

def geocode_publishers():
    logger.info("Starting geocoding publishers script")

    conn = None
    cursor = None
    try:
        conn = get_connection()
        logger.debug("Database connection established")
        cursor = conn.cursor()
        
        # Publisher ohne Geodaten abrufen
        logger.debug("Fetching publishers without geocode data")
        cursor.execute("""
            SELECT 
                p.id, 
                p.name, 
                c.iso_code
            FROM 
                publishers AS p
            JOIN 
                countries AS c
            ON 
                p.country_id = c.id
            WHERE 
                p.latitude IS NULL 
                OR p.longitude IS NULL
            ORDER BY 
                p.id DESC
        """)

        publishers = cursor.fetchall()
        logger.info(f"Publishers to geocode: {len(publishers)}")
        logger.debug(f"Publisher list: {publishers}")

        for publisher_id, publisher_name, iso_code in publishers:
            logger.info(f"Geocoding publisher ID {publisher_id} - {publisher_name}")

            # Geokodierung durchführen
            start_time = time.time()
            location_data = geocode_with_rate_limit(publisher_name, iso_code)
            duration = time.time() - start_time
            logger.debug(f"Geocoding took {duration:.2f} seconds for '{publisher_name}'")

            if location_data:
                latitude, longitude, country_name, city, country_code = location_data
                logger.debug(f"Geocode result for '{publisher_name}': latitude={latitude}, longitude={longitude}, country_name={country_name}, city={city}, country_code={country_code}")

                # Publisher aktualisieren
                try:
                    logger.debug(f"Updating publisher ID {publisher_id} with geocode data")
                    cursor.execute("""
                        UPDATE publishers
                        SET latitude = %s,
                            longitude = %s,
                            city = %s
                        WHERE id = %s
                    """, (latitude, longitude, city, publisher_id))
                    conn.commit()
                    logger.info(f"Updated publisher ID {publisher_id} with geocoded data")
                except Exception as e:
                    conn.rollback()
                    logger.error(f"Failed to update publisher ID {publisher_id}: {e}")
            else:
                logger.warning(f"Could not geocode publisher ID {publisher_id} - {publisher_name}")

    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Error during geocoding publishers: {e}")
    finally:
        if cursor:
            cursor.close()
            logger.debug("Database cursor closed")
        if conn:
            return_connection(conn)
            logger.debug("Database connection returned")

    logger.info("Geocoding publishers script completed")

if __name__ == '__main__':
    geocode_publishers()
