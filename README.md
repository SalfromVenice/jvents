# Tokyo Events — Backend

API Rails per aggregare e servire eventi a Tokyo, con scraping automatico e ricerca geospaziale.

---

## Stack

- **Ruby on Rails 8** — API-only
- **PostgreSQL** — database principale
- **Nokogiri** — scraping HTML
- **Solid Queue** — job queue (via Puma)
- **Docker / Kamal** — containerizzazione e deploy

---

## Funzionalità principali

- Scraping automatico di eventi da sorgente esterna (Tokyo, finestra di 7 giorni)
- Ricerca geospaziale con formula di Haversine — filtra eventi per raggio in km
- Deduplicazione automatica via indice univoco su `title + start_time + address`
- Eliminazione automatica degli eventi scaduti
- API RESTful con namespace versionato (`/api/v1/`)
- CORS configurabile via variabile d'ambiente

---

## Struttura del progetto

```
backend/
├── app/
│   ├── controllers/
│   │   └── api/v1/
│   │       └── events_controller.rb   # Index (con filtro geo) + Show
│   └── models/
│       └── event.rb                   # Validazioni, scope, Haversine
├── lib/tasks/
│   ├── scrape_events.rake             # Task scraping eventi
│   └── delete_expired.rake            # Task pulizia eventi scaduti
├── config/
│   ├── routes.rb
│   ├── initializers/cors.rb
│   └── recurring.yml                  # Job schedulati (Solid Queue)
└── db/
    └── schema.rb
```

---

## Schema del database

| Campo        | Tipo     | Note                       |
| ------------ | -------- | -------------------------- |
| `title`      | string   | obbligatorio               |
| `start_time` | datetime | obbligatorio               |
| `end_time`   | datetime |                            |
| `venue`      | string   |                            |
| `address`    | string   | obbligatorio               |
| `latitude`   | float    |                            |
| `longitude`  | float    |                            |
| `url`        | string   | sito ufficiale dell'evento |
| `image_url`  | string   | validazione formato URL    |
| `cost`       | string   |                            |

Indice univoco su `(title, start_time, address)` per evitare duplicati.

---

## API Endpoints

### `GET /api/v1/events`

Restituisce eventi in corso o futuri.

**Parametri opzionali:**

| Parametro | Tipo  | Default | Descrizione                |
| --------- | ----- | ------- | -------------------------- |
| `lat`     | float | —       | Latitudine centro ricerca  |
| `lng`     | float | —       | Longitudine centro ricerca |
| `radius`  | float | 10      | Raggio in km               |

**Esempio:**

```
GET /api/v1/events?lat=35.6762&lng=139.6503&radius=5
```

---

### `GET /api/v1/events/:id`

Restituisce un singolo evento per ID.

---

## Setup locale

### Prerequisiti

- Ruby 3.4.2
- PostgreSQL
- Bundler

### Installazione

```bash
git clone <repo-url>
cd backend

bundle install

# Crea un file .env nella root con le variabili necessarie
cp .env.example .env

# Setup database
bin/rails db:create db:migrate

# Avvia il server
bin/rails server
```

### Variabili d'ambiente

| Variabile      | Descrizione                               |
| -------------- | ----------------------------------------- |
| `DATABASE_URL` | URL di connessione PostgreSQL             |
| `BASE_URL`     | URL base del sito da cui fare scraping    |
| `CORS_ORIGINS` | Origine autorizzata per le richieste CORS |

---

## Rake Tasks

### Scraping eventi

Scarica gli eventi dei prossimi 7 giorni dalla sorgente esterna e li salva nel database. Include un delay casuale tra 1 e 3 secondi per ogni richiesta.

```bash
bin/rails scrape:events
```

### Eliminazione eventi scaduti

```bash
bin/rails events:delete_expired
```

---

## Deploy

Il progetto è configurato per il deploy con **Kamal** e Docker.

### Build immagine

```bash
docker build -t jvents .
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<master_key> \
  --name jvents jvents
```

### Deploy con Kamal

```bash
# Configura config/deploy.yml con host, registry e dominio
bin/kamal deploy
```

Kamal gestisce: zero-downtime deploy, SSL automatico via Let's Encrypt, rolling restarts.

---

## Note tecniche

**Ricerca geospaziale:** la query usa direttamente la formula di Haversine in SQL, senza estensioni PostGIS. Pratico per dataset piccoli/medi; per volumi elevati valutare l'aggiunta di PostGIS con indice spaziale.

**Scraping:** il task usa `open-uri` + `Nokogiri`. Il rate limiting è gestito con sleep casuali. Gli eventi già presenti vengono ignorati grazie a `find_or_create_by`.

**Pulizia automatica:** `recurring.yml` è configurato per Solid Queue. Si può aggiungere la schedulazione del task `events:delete_expired` direttamente lì.
