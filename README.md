# GoogleMapTimes

GoogleMapTimes ist ein Open-Source-Projekt, das Nachrichten von Google News aus allen von Google unterstützten Ländern sammelt, verarbeitet und auf einer interaktiven Karte anzeigt. Mit Python-Skripten werden GoogleNews-RSS-Feeds heruntergeladen, geparst und in einer PostgreSQL-Datenbank gespeichert. Publisher werden mittels OpenStreetMap (Nominatim) geokodet, sodass ihre Position präzise auf der Karte dargestellt werden kann. Die mobile App ist in Flutter geschrieben und bietet ein app-ähnliches Nutzererlebnis.

---

## Inhaltsverzeichnis

- [Überblick](#überblick)
- [Features](#features)
- [Technologie-Stack](#technologie-stack)
- [Projektstruktur](#projektstruktur)
- [Verwendung](#verwendung)
- [Mobile Optimierung & Homescreen-Pinning](#mobile-optimierung--homescreen-pinning)


---

## Überblick

GoogleMapTimes aggregiert Nachrichten aus den GoogleNews-RSS-Feeds und speichert sie in einer PostgreSQL-Datenbank. Dabei werden die Publisher der Nachrichten mittels OpenStreetMap geokodet, sodass sie auf einer interaktiven Karte visualisiert werden können. Diese Lösung ermöglicht es, Nachrichten von überall auf der Welt festzuhalten und sie geografisch aufzubereiten – ideal für Nutzer, die stets den Überblick über internationale Nachrichten behalten möchten.

---

## Features

- **Nachrichtenaggregation & Parsing:**
  - Download der GoogleNews-RSS-Feeds für verschiedene Länder und Themen.
  - Parsing der Feeds und Speicherung der Artikel in einer PostgreSQL-Datenbank.
  - Dynamisches Hinzufügen von Feeds mittels eines Python-Skripts.

- **Geokodierung:**
  - Geokodierung der Publisher mit Hilfe der OpenStreetMap-Nominatim API.
  - Aktualisierung der Datenbank mit präzisen Koordinaten und Standortinformationen.

- **Interaktive Karte & App:**
  - Anzeige der geokodierten Publisher als Marker auf einer interaktiven Karte.
  - Flutter-basierte mobile App, die ein app-ähnliches Erlebnis bietet.
  - Nutzung von [Flutter Map](https://pub.dev/packages/flutter_map) für die Kartenansicht und [Sliding Up Panel](https://pub.dev/packages/sliding_up_panel) für zusätzliche Informationen.

- **API Endpoints:**
  - Bereitstellung einer REST-API (unter anderem über FastAPI) für den Zugriff auf Nachrichten, Themen und Publisher.
  - Dynamische Such- und Filterfunktionen für Nachrichten (z. B. nach Keywords, Themen, Ländern, Veröffentlichungszeitraum).

- **Erweiterte Funktionen:**
  - Autocomplete bei der Suche.
  - Gruppierung von Artikeln nach Publisher.

---

## Technologie-Stack

- **Backend & Scripte:**
  - **Python:** Für das Herunterladen, Parsen und Verarbeiten der RSS-Feeds sowie zur Geokodierung.
  - **FastAPI:** Bereitstellung der REST-API.
  - **PostgreSQL:** Speicherung der Artikel, Publisher, Themen und weiterer Metadaten.

- **Frontend:**
  - **Flutter:** Entwicklung der mobilen App und Web-Oberfläche.
  - **Dart:** Umsetzung der App-Logik und Services (z. B. `ApiService`).

- **Externe Dienste:**
  - **GoogleNews-RSS:** Quelle der Nachrichtenfeeds.
  - **OpenStreetMap (Nominatim):** Geokodierungsservice.

---

## Projektstruktur

```plaintext
GoogleMapTimes/
├── assets/
│   ├── add_feed.py               # Fügt RSS-Feeds für unterschiedliche Länder und Themen hinzu
│   ├── geocode_publishers.py     # Geokodierung der Publisher über OpenStreetMap
│   ├── parse_feeds.py            # Parsing der Feeds und Speicherung der neuen Artikel
│   ├── main.py                   # API-Server (FastAPI) zur Bereitstellung der REST-API
│   └── ...                       # Weiter Hilfsscripte und Dateien
│
├── lib/
│   ├── models/                   # Objektorientierte Modellklassen
│   │   ├── article.dart          
│   │   ├── publisher.dart        
│   │   ├── publisher_with_articles.dart
│   │   ├── publishers_articles_list_response.dart
│   │   └── topic.dart            
│   │
│   ├── screens/
│   │   └── home_screen.dart      # Hauptbildschirm mit interaktiver Karte und Filteroptionen
│   │
│   ├── services/
│   │   └── api_service.dart      # API-Service zur Kommunikation mit dem Backend
│   │
│   └── main.dart                 # Einstiegspunkt der Flutter-App
│
└── README.md                     # Diese Datei 
```
---

# Verwendung

## Interaktive Karte und App

### Karte
Die Hauptansicht zeigt eine interaktive Karte, auf der die geokodierten Publisher als Marker dargestellt sind. Ein Tippen auf einen Marker öffnet ein Panel, in dem die zugehörigen Nachrichtenartikel angezeigt werden.

### Suche & Filter
Über die Suchleiste und diverse Filteroptionen (Themen, Ländercode, Zeitraum) können Artikel gezielt gesucht werden. Autocomplete-Vorschläge erleichtern die Eingabe.

### API Endpoints
Die REST-API stellt unter anderem folgende Endpunkte bereit:
- `GET /api/v01/news` – Abruf von Nachrichtenartikeln
- `GET /api/v01/topics` – Abruf der verfügbaren Themen
- `GET /api/v01/publishers` – Abruf der Publisher
- `GET /api/v01/search` – Erweiterte Suche mit Filtern

## API-Service in Flutter
Der `ApiService` in `lib/services/api_service.dart` übernimmt die Kommunikation mit den Backend-Endpoints.  
Methoden wie `fetchPublishers`, `fetchNews`, `fetchTopics`, `fetchAutocompleteSuggestions` und `searchPublishersWithArticles` bieten eine einfache Schnittstelle zur Datenabfrage.

---

# Mobile Optimierung & Homescreen-Pinning
Die Webseite ist speziell für mobile Geräte optimiert und bietet ein app-ähnliches Erlebnis:

## iOS
Öffne die Webseite in Safari, tippe auf das Teilen-Symbol und wähle „Zum Home-Bildschirm hinzufügen“. Dadurch wird ein Icon auf dem Homescreen erstellt, über das die Webseite im Vollbildmodus startet.

## Android
Öffne die Webseite in Chrome, tippe auf die drei Punkte oben rechts und wähle „Zum Startbildschirm hinzufügen“. Auch hier wird ein Shortcut erstellt, der die Webseite im Vollbildmodus öffnet.

> **Hinweis:** In der Browser-Version kann das Zoomen deaktiviert sein, um ein konsistentes App-Erlebnis zu gewährleisten.
