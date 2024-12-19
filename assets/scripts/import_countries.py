# import_countries.py

import csv
import logging
from db_connection import get_connection, return_connection, close_all_connections

# Logging konfigurieren
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def import_countries(csv_file):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        conn.autocommit = True
        if conn is None:
            logger.error("Keine Datenbankverbindung verfügbar")
            return

        cursor = conn.cursor()

        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.reader(f, delimiter=';')
            for row in reader:
                if len(row) != 2:
                    logger.warning(f"Ungültige Zeile in CSV-Datei: {row}")
                    continue

                country_name = row[0].strip()
                iso_code = row[1].strip().upper()

                # Einfügen in die Datenbank
                try:
                    cursor.execute("""
                        INSERT INTO countries (country_name, iso_code)
                        VALUES (%s, %s)
                        ON CONFLICT (iso_code) DO NOTHING
                    """, (country_name, iso_code))
                    conn.commit()
                    logger.info(f"Land eingefügt: {country_name} ({iso_code})")
                except Exception as e:
                    conn.rollback()
                    logger.error(f"Fehler beim Einfügen von {country_name} ({iso_code}): {e}")

    except Exception as e:
        logger.error(f"Fehler beim Importieren der Länder: {e}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            return_connection(conn)
        close_all_connections()

if __name__ == '__main__':
    import_countries('/Users/peterwolters/Desktop/Uni/3_Semester/Geoinformatik/googlemaptimes/data/country_iso_codes.csv')
