# api/main.py

from fastapi import FastAPI, HTTPException, Depends, Query
import logging
from typing import List, Optional
from datetime import datetime

from api.schemas import (
    ArticleBase,
    NewsListResponse,
    NewsDetailResponse,
    PublisherBase,
    TopicBase,
    TopicListResponse,
    PublisherListResponse,
    AutocompleteResponse,
    LocationBase,
    PublisherWithArticles,
    PublishersArticlesListResponse,
)

from db_connection import get_connection, return_connection
from logging_config import setup_logging

import psycopg2
from psycopg2.extras import RealDictCursor

# Logging konfigurieren
setup_logging()
logger = logging.getLogger(__name__)

app = FastAPI(
    title="News API",
    description="API für Nachrichten mit Georeferenzierung",
    version="1.0.0"
)

# Dependency für den Datenbankzugriff
def get_db():
    conn = get_connection()
    if not conn:
        logger.error("Datenbankverbindung konnte nicht hergestellt werden")
        raise HTTPException(status_code=500, detail="Datenbankverbindung konnte nicht hergestellt werden")
    try:
        yield conn
    finally:
        return_connection(conn)

@app.get("/api/v01/news", response_model=NewsListResponse)
def get_news(
    keywords: Optional[str] = Query(None, description="Schlüsselwörter für die Suche"),
    topics: Optional[List[int]] = Query(None, description="Themen-IDs zum Filtern"),
    publishers: Optional[List[int]] = Query(None, description="Publisher-IDs zum Filtern"),
    country: Optional[str] = Query(None, description="ISO-Ländercode zum Filtern"),
    date_from: Optional[datetime] = Query(None, description="Startdatum des Veröffentlichungszeitraums"),
    date_to: Optional[datetime] = Query(None, description="Enddatum des Veröffentlichungszeitraums"),
    page: int = Query(1, ge=1, description="Seitenzahl"),
    page_size: int = Query(200, ge=1, le=1000, description="Anzahl der Artikel pro Seite"),
    db: psycopg2.extensions.connection = Depends(get_db)
):
    logger.debug("GET /news aufgerufen mit Parametern: keywords=%s, topics=%s, publishers=%s, country=%s, date_from=%s, date_to=%s, page=%s, page_size=%s",
                 keywords, topics, publishers, country, date_from, date_to, page, page_size)
    
    try:
        with db.cursor(cursor_factory=RealDictCursor) as cursor:
            query = """
                SELECT 
                    articles.id, articles.title, articles.link, articles.pub_date,
                    publishers.id AS publisher_id, publishers.name AS publisher_name,
                    topics.id AS topic_id, topics.topic_name AS topic_name,
                    publishers.latitude, publishers.longitude, publishers.country_id, publishers.city,
                    countries.country_name, countries.iso_code
                FROM articles
                JOIN publishers ON articles.publisher_id = publishers.id
                JOIN feeds ON articles.feed_id = feeds.id
                JOIN topics ON feeds.topic_id = topics.id
                JOIN countries ON publishers.country_id = countries.id
                WHERE 1=1
            """
            params = []
            
            if keywords:
                query += " AND articles.title ILIKE %s"
                keyword_param = f"%{keywords}%"
                params.extend([keyword_param])
                logger.debug("Filter angewendet: keywords=%s", keywords)
            
            if topics:
                query += " AND articles.topic_id = ANY(%s)"
                params.append(topics)
                logger.debug("Filter angewendet: topics=%s", topics)
            
            if publishers:
                query += " AND articles.publisher_id = ANY(%s)"
                params.append(publishers)
                logger.debug("Filter angewendet: publishers=%s", publishers)
            
            if country:
                query += " AND countries.iso_code ILIKE %s"
                params.append(country)
                logger.debug("Filter angewendet: country=%s", country)
            
            if date_from:
                query += " AND articles.pub_date >= %s"
                params.append(date_from)
                logger.debug("Filter angewendet: date_from=%s", date_from)
            
            if date_to:
                query += " AND articles.pub_date <= %s"
                params.append(date_to)
                logger.debug("Filter angewendet: date_to=%s", date_to)
            
            # Zählen der Gesamtanzahl
            count_query = "SELECT COUNT(*) FROM (" + query + ") AS count_table"
            cursor.execute(count_query, params)
            total = cursor.fetchone()['count']
            logger.debug("Gesamtanzahl der gefundenen Artikel: %s", total)
            
            # Hinzufügen von Sortierung, Paginierung
            query += " ORDER BY articles.pub_date DESC OFFSET %s LIMIT %s"
            params.extend([(page - 1) * page_size, page_size])
            logger.debug("Pagination angewendet: page=%s, page_size=%s", page, page_size)
            
            cursor.execute(query, params)
            articles = cursor.fetchall()
            logger.debug("Anzahl der zurückgegebenen Artikel: %s", len(articles))
            
            # Umwandeln der Ergebnisse in die gewünschte Struktur
            items = []
            for article in articles:
                logger.debug("Verarbeiteter Artikel: %s", article)
                
                location = LocationBase(
                    latitude=article['latitude'],
                    longitude=article['longitude'],
                    country=article['country_name'],
                    city=article['city']
                )
                
                publisher = PublisherBase(
                    id=article['publisher_id'],
                    name=article['publisher_name'],
                    location=location
                )
                
                topic = TopicBase(
                    id=article['topic_id'],
                    topic_name=article['topic_name']
                )
                
                article_base = ArticleBase(
                    id=article['id'],
                    title=article['title'],
                    link=article['link'],
                    pub_date=article['pub_date'],
                    publisher=publisher,
                    topic=topic
                )
                
                items.append(article_base)
            
            return NewsListResponse(
                total=total,
                page=page,
                page_size=page_size,
                items=items
            )
    except Exception as e:
        logger.error("Fehler beim Abrufen der Nachrichten: %s", e)
        raise HTTPException(status_code=500, detail="Interner Serverfehler")

@app.get("/api/v01/news/{article_id}", response_model=NewsDetailResponse)
def get_news_detail(article_id: int, db: psycopg2.extensions.connection = Depends(get_db)):
    logger.debug("GET /news/%s aufgerufen", article_id)
    
    try:
        with db.cursor(cursor_factory=RealDictCursor) as cursor:
            query = """
                SELECT 
                    articles.id, articles.title, articles.link, articles.pub_date,
                    publishers.id AS publisher_id, publishers.name AS publisher_name,
                    topics.id AS topic_id, topics.topic_name AS topic_name,
                    publishers.latitude, publishers.longitude, publishers.country_id, publishers.city,
                    countries.country_name, countries.iso_code
                FROM articles
                JOIN publishers ON articles.publisher_id = publishers.id
                JOIN feeds ON articles.feed_id = feeds.id
                JOIN topics ON feeds.topic_id = topics.id
                JOIN countries ON publishers.country_id = countries.id
                WHERE articles.id = %s
            """
            cursor.execute(query, (article_id,))
            article = cursor.fetchone()
            
            if not article:
                logger.warning("Artikel mit ID %s nicht gefunden", article_id)
                raise HTTPException(status_code=404, detail="Artikel nicht gefunden")
            
            logger.debug("Artikel gefunden: %s", article)
            
            location = LocationBase(
                latitude=article['latitude'],
                longitude=article['longitude'],
                country=article['country_name'],
                city=article['city']
            )
            
            publisher = PublisherBase(
                id=article['publisher_id'],
                name=article['publisher_name'],
                location=location
            )
            
            topic = TopicBase(
                id=article['topic_id'],
                name=article['topic_name']
            )
            
            item = {
                "id": article['id'],
                "title": article['title'],
                "link": article['link'],
                "pub_date": article['pub_date'],
                "publisher": publisher,
                "topic": topic,
                "additional_info": {}  # Falls weitere Informationen vorhanden sind
            }
            
            return NewsDetailResponse(**item)
    except Exception as e:
        logger.error("Fehler beim Abrufen des Artikels mit ID %s: %s", article_id, e)
        raise HTTPException(status_code=500, detail="Interner Serverfehler")

@app.get("/api/v01/topics", response_model=TopicListResponse)
def get_topics(db: psycopg2.extensions.connection = Depends(get_db)):
    logger.debug("GET /topics aufgerufen")
    
    try:
        with db.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute("SELECT id, topic_name FROM topics ORDER BY topic_name ASC")
            topics = cursor.fetchall()
            logger.debug("Anzahl der zurückgegebenen Themen: %s", len(topics))
            return TopicListResponse(items=topics)
    except Exception as e:
        logger.error("Fehler beim Abrufen der Themen: %s", e)
        raise HTTPException(status_code=500, detail="Interner Serverfehler")

@app.get("/api/v01/publishers", response_model=PublisherListResponse)
def get_publishers(
    country: Optional[str] = Query(None, description="ISO-Ländercode zum Filtern"),
    db: psycopg2.extensions.connection = Depends(get_db)
):
    logger.debug("GET /publishers aufgerufen mit country=%s", country)
    
    try:
        with db.cursor(cursor_factory=RealDictCursor) as cursor:
            query = """
                SELECT 
                    publishers.id, publishers.name, publishers.latitude, publishers.longitude,
                    publishers.country_id, publishers.city,
                    countries.country_name, countries.iso_code
                FROM publishers
                JOIN countries ON publishers.country_id = countries.id
                WHERE 1=1
            """
            params = []
            
            if country:
                query += " AND countries.iso_code ILIKE %s"
                params.append(country)
                logger.debug("Filter angewendet: country=%s", country)
            
            query += " ORDER BY publishers.name ASC"
            cursor.execute(query, params)
            publishers = cursor.fetchall()
            logger.debug("Anzahl der zurückgegebenen Publisher: %s", len(publishers))
            
            items = []
            for publisher in publishers:
                location = LocationBase(
                    latitude=publisher['latitude'],
                    longitude=publisher['longitude'],
                    country=publisher['country_name'],
                    city=publisher['city']
                )
                
                publisher_base = PublisherBase(
                    id=publisher['id'],
                    name=publisher['name'],
                    location=location
                )
                
                items.append(publisher_base)
            
            return PublisherListResponse(items=items)
    except Exception as e:
        logger.error("Fehler beim Abrufen der Publisher: %s", e)
        raise HTTPException(status_code=500, detail="Interner Serverfehler")

@app.get("/api/v01/search/autocomplete", response_model=AutocompleteResponse)
def autocomplete_search(q: str = Query(..., min_length=1, description="Eingabewort für Autocomplete"), db: psycopg2.extensions.connection = Depends(get_db)):
    logger.debug("GET /search/autocomplete aufgerufen mit q=%s", q)
    
    try:
        with db.cursor(cursor_factory=RealDictCursor) as cursor:
            # Vorschläge aus Themen
            cursor.execute("""
                SELECT topic_name FROM topics
                WHERE topic_name ILIKE %s
                ORDER BY topic_name ASC
                LIMIT 5
            """, (f"%{q}%",))
            topics = cursor.fetchall()
            
            # Vorschläge aus Publishern
            cursor.execute("""
                SELECT name FROM publishers
                WHERE name ILIKE %s
                ORDER BY name ASC
                LIMIT 5
            """, (f"%{q}%",))
            publishers = cursor.fetchall()
            
            suggestions = [t['topic_name'] for t in topics] + [p['name'] for p in publishers]
            logger.debug("Autocomplete-Vorschläge: %s", suggestions)
            
            return AutocompleteResponse(suggestions=suggestions)
    except Exception as e:
        logger.error("Fehler beim Autocomplete: %s", e)
        raise HTTPException(status_code=500, detail="Interner Serverfehler")

@app.get("/api/v01/search", response_model=PublishersArticlesListResponse)
def search_news(
    keywords: Optional[str] = Query(None, description="Schlüsselwörter für die Suche"),
    topics: Optional[List[int]] = Query(None, description="Themen-IDs zum Filtern"),
    publishers: Optional[List[int]] = Query(None, description="Publisher-IDs zum Filtern"),
    country: Optional[str] = Query(None, description="ISO-Ländercode zum Filtern"),
    date_from: Optional[datetime] = Query(None, description="Startdatum des Veröffentlichungszeitraums"),
    date_to: Optional[datetime] = Query(None, description="Enddatum des Veröffentlichungszeitraums"),
    page: int = Query(1, ge=1, description="Seitenzahl"),
    page_size: int = Query(200, ge=1, le=1000, description="Anzahl der Artikel pro Seite"),
    db: psycopg2.extensions.connection = Depends(get_db)
):
    """
    Sucht nach Artikeln anhand verschiedener Filter und gruppiert sie nach Publisher.
    Gibt nur jene Publisher zurück, die mind. einen passenden Artikel haben.
    """
    logger.debug("GET /search aufgerufen mit Parametern: keywords=%s, topics=%s, publishers=%s, country=%s, date_from=%s, date_to=%s, page=%s, page_size=%s",
                 keywords, topics, publishers, country, date_from, date_to, page, page_size)

    try:
        with db.cursor(cursor_factory=RealDictCursor) as cursor:
            # 1) Gleicher Start wie bei /news, nur ohne finalen COUNT.
            query = """
                SELECT 
                    articles.id AS article_id,
                    articles.title AS article_title,
                    articles.link AS article_link,
                    articles.pub_date AS article_pub_date,
                    publishers.id AS publisher_id,
                    publishers.name AS publisher_name,
                    publishers.latitude,
                    publishers.longitude,
                    publishers.country_id,
                    publishers.city,
                    countries.country_name,
                    countries.iso_code,
                    topics.id AS topic_id,
                    topics.topic_name AS topic_name
                FROM articles
                JOIN publishers ON articles.publisher_id = publishers.id
                JOIN feeds ON articles.feed_id = feeds.id
                JOIN topics ON feeds.topic_id = topics.id
                JOIN countries ON publishers.country_id = countries.id
                WHERE 1=1
            """
            params = []

            if keywords:
                query += " AND articles.title ILIKE %s"
                keyword_param = f"%{keywords}%"
                params.append(keyword_param)
            
            if topics:
                query += " AND articles.topic_id = ANY(%s)"
                params.append(topics)
            
            if publishers:
                query += " AND articles.publisher_id = ANY(%s)"
                params.append(publishers)
            
            if country:
                query += " AND countries.iso_code ILIKE %s"
                params.append(country)
            
            if date_from:
                query += " AND articles.pub_date >= %s"
                params.append(date_from)
            
            if date_to:
                query += " AND articles.pub_date <= %s"
                params.append(date_to)

            # Sortieren, aber noch KEIN Offset/LIMIT anwenden,
            # weil wir erst Publisher-Artikel-Gruppen bilden wollen.
            query += " ORDER BY articles.pub_date DESC"

            # 2) Hole alle passenden Datensätze
            cursor.execute(query, params)
            rows = cursor.fetchall()

            logger.debug("Anzahl der gefundenen Datensätze vor Gruppierung: %s", len(rows))

            # 3) Gruppierung nach Publisher
            #    Key = publisher_id, Value = { "publisher": PublisherBase, "articles": [ArticleBase...] }
            grouped = {}

            for row in rows:
                pub_id = row["publisher_id"]
                
                # Publisher-Objekt erzeugen (wird für jeden Artikel identisch sein)
                location = LocationBase(
                    latitude=row['latitude'],
                    longitude=row['longitude'],
                    country=row['country_name'],
                    city=row['city']
                )
                publisher_obj = PublisherBase(
                    id=row['publisher_id'],
                    name=row['publisher_name'],
                    location=location
                )

                # Topic-Objekt
                topic_obj = TopicBase(
                    id=row['topic_id'],
                    topic_name=row['topic_name']
                )

                # Artikel-Objekt
                article_obj = ArticleBase(
                    id=row['article_id'],
                    title=row['article_title'],
                    link=row['article_link'],
                    pub_date=row['article_pub_date'],
                    publisher=publisher_obj,
                    topic=topic_obj
                )

                if pub_id not in grouped:
                    grouped[pub_id] = {
                        "publisher": publisher_obj,
                        "articles": []
                    }
                
                grouped[pub_id]["articles"].append(article_obj)
            
            # 4) Gesamte Anzahl passender Artikel
            total_articles = sum(len(g["articles"]) for g in grouped.values())
            # 5) Sortierung der Publisher-Gruppen kann optional sein, z. B. nach Publisher-Name
            #    grouped_values = sorted(grouped.values(), key=lambda x: x["publisher"].name)
            grouped_values = list(grouped.values())

            # 6) Pagination auf Ebene der Publisher
            #    -> page, page_size anwenden
            start_idx = (page - 1) * page_size
            end_idx = start_idx + page_size
            paginated = grouped_values[start_idx:end_idx]

            # 7) In das gewünschte Schema überführen
            items = []
            for entry in paginated:
                items.append(
                    PublisherWithArticles(
                        publisher=entry["publisher"],
                        articles=entry["articles"]
                    )
                )

            return PublishersArticlesListResponse(
                total_publishers=len(grouped_values),  # Gesamtanzahl Publisher
                total_articles=total_articles,         # Gesamtanzahl Artikel
                page=page,
                page_size=page_size,
                items=items
            )
    except Exception as e:
        logger.error("Fehler beim /api/v01/search: %s", e)
        raise HTTPException(status_code=500, detail="Interner Serverfehler")