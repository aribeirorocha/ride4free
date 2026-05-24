"""SQLite persistence for Ride4Free (local dev)."""

from __future__ import annotations

import hashlib
import secrets
import sqlite3
import math
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Default DB path next to this package (override with RIDE4FREE_DB_PATH)
_DB_DIR = Path(__file__).resolve().parent
DEFAULT_DB_PATH = _DB_DIR / "ride4free.db"


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def normalize_destination(text: str) -> str:
    """Single key for matching passenger ↔ driver destinations (MVP)."""
    return " ".join(text.lower().strip().split())


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 100_000)
    return f"{salt}${dk.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        salt, _, hex_digest = stored.partition("$")
        if not salt or not hex_digest:
            return False
        dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 100_000)
        return secrets.compare_digest(dk.hex(), hex_digest)
    except (ValueError, AttributeError):
        return False


def get_db_path() -> Path:
    import os

    return Path(os.environ.get("RIDE4FREE_DB_PATH", str(DEFAULT_DB_PATH)))


@contextmanager
def get_connection():
    path = get_db_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


SCHEMA = """
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE COLLATE NOCASE,
    password_hash TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
    token TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS passenger_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    origin_lat REAL,
    origin_lng REAL,
    destination_norm TEXT,
    destination_display TEXT NOT NULL,
    passenger_count INTEGER NOT NULL DEFAULT 1 CHECK (passenger_count >= 1),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'cancelled', 'fulfilled')),
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_passenger_dest ON passenger_requests(destination_norm, status);

CREATE TABLE IF NOT EXISTS driver_offers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    origin_lat REAL,
    origin_lng REAL,
    destination_lat REAL,
    destination_lng REAL,
    destination_norm TEXT NOT NULL,
    destination_display TEXT NOT NULL,
    available_seats INTEGER NOT NULL CHECK (available_seats >= 0),
    departure_time TEXT, 
    description TEXT,
    vehicle_info TEXT,    
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'full', 'cancelled')),
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_driver_dest ON driver_offers(destination_norm, status);

CREATE TABLE IF NOT EXISTS ride_bookings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    driver_offer_id INTEGER UNIQUE REFERENCES driver_offers(id) ON DELETE CASCADE,
    passenger_request_id INTEGER UNIQUE REFERENCES passenger_requests(id) ON DELETE CASCADE,
    booked_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL,
    CHECK ((driver_offer_id IS NOT NULL) != (passenger_request_id IS NOT NULL))
);

CREATE TABLE IF NOT EXISTS ride_join_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    driver_offer_id INTEGER NOT NULL REFERENCES driver_offers(id) ON DELETE CASCADE,
    passenger_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    passenger_count INTEGER NOT NULL DEFAULT 1 CHECK (passenger_count >= 1),
    origin_display TEXT,
    destination_display TEXT,
    departure_time TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'awaiting_passenger', 'confirmed', 'declined', 'cancelled', 'expired'
    )),
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_join_requests_offer ON ride_join_requests(driver_offer_id, status);

CREATE TABLE IF NOT EXISTS active_rides (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    driver_offer_id INTEGER NOT NULL REFERENCES driver_offers(id) ON DELETE CASCADE,
    join_request_id INTEGER UNIQUE REFERENCES ride_join_requests(id),
    driver_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    passenger_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'matched' CHECK (status IN ('matched', 'in_progress', 'completed')),
    driver_in_car INTEGER NOT NULL DEFAULT 0,
    passenger_in_car INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    started_at TEXT,
    completed_at TEXT
);

CREATE TABLE IF NOT EXISTS ride_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    active_ride_id INTEGER NOT NULL REFERENCES active_rides(id) ON DELETE CASCADE,
    sender_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    active_ride_id INTEGER NOT NULL REFERENCES active_rides(id) ON DELETE CASCADE,
    rater_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rated_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    stars INTEGER NOT NULL CHECK (stars >= 1 AND stars <= 5),
    created_at TEXT NOT NULL,
    UNIQUE(active_ride_id, rater_user_id)
);
"""

MIGRATION_SQL = """
ALTER TABLE driver_offers ADD COLUMN vehicle_info TEXT;
ALTER TABLE users ADD COLUMN vehicle_info TEXT;
ALTER TABLE passenger_requests ADD COLUMN origin_display TEXT;
ALTER TABLE passenger_requests ADD COLUMN departure_time TEXT;
ALTER TABLE user_ratings ADD COLUMN criteria_json TEXT;

CREATE TABLE IF NOT EXISTS user_credits (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    balance INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS credit_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount_delta INTEGER NOT NULL,
    description TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_credit_tx_user ON credit_transactions(user_id, created_at DESC);

"""

_JOIN_REQUEST_MESSAGES_DDL = """
CREATE TABLE IF NOT EXISTS join_request_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    join_request_id INTEGER NOT NULL REFERENCES ride_join_requests(id) ON DELETE CASCADE,
    sender_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_join_msg ON join_request_messages(join_request_id, created_at);
"""

REQUEST_EXPIRY_HOURS = 12
CREDITS_RIDE_COMPLETE = 10
CREDITS_BOOKING_COST = 5

RATING_CRITERIA_KEYS = (
    "pontualidade",
    "simpatia",
    "limpeza_veiculo",
    "comunicacao",
)


def _parse_iso(ts: str) -> datetime:
    return datetime.fromisoformat(ts.replace("Z", "+00:00"))


def is_not_expired(created_at: str, hours: int = REQUEST_EXPIRY_HOURS) -> bool:
    try:
        created = _parse_iso(created_at)
        if created.tzinfo is None:
            created = created.replace(tzinfo=timezone.utc)
        return datetime.now(timezone.utc) - created < timedelta(hours=hours)
    except (ValueError, TypeError):
        return False


def _ensure_join_request_messages_table(conn: sqlite3.Connection) -> None:
    conn.executescript(_JOIN_REQUEST_MESSAGES_DDL)


def _migrate_join_requests_table(conn: sqlite3.Connection) -> None:
    tables = {
        r["name"]
        for r in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table'"
        ).fetchall()
    }
    if "ride_join_requests" in tables:
        row = conn.execute(
            "SELECT sql FROM sqlite_master WHERE type='table' AND name='ride_join_requests'"
        ).fetchone()
        if row and "awaiting_passenger" in (row["sql"] or ""):
            return

    # Recover from a previously interrupted migration.
    if "ride_join_requests_new" in tables:
        conn.execute("PRAGMA foreign_keys=OFF")
        try:
            if "ride_join_requests" in tables:
                conn.execute("DROP TABLE ride_join_requests")
            conn.execute("ALTER TABLE ride_join_requests_new RENAME TO ride_join_requests")
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_join_requests_offer "
                "ON ride_join_requests(driver_offer_id, status)"
            )
        finally:
            conn.execute("PRAGMA foreign_keys=ON")
        return

    if "ride_join_requests" not in tables:
        return

    # active_rides.join_request_id and join_request_messages block DROP without this.
    conn.execute("PRAGMA foreign_keys=OFF")
    try:
        conn.execute("DROP TABLE IF EXISTS join_request_messages")
        conn.executescript(
            """
            CREATE TABLE ride_join_requests_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                driver_offer_id INTEGER NOT NULL REFERENCES driver_offers(id) ON DELETE CASCADE,
                passenger_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                passenger_count INTEGER NOT NULL DEFAULT 1 CHECK (passenger_count >= 1),
                origin_display TEXT,
                destination_display TEXT,
                departure_time TEXT,
                status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
                    'pending', 'awaiting_passenger', 'confirmed', 'declined', 'cancelled', 'expired'
                )),
                created_at TEXT NOT NULL
            );
            INSERT INTO ride_join_requests_new
                (id, driver_offer_id, passenger_user_id, passenger_count, status, created_at)
            SELECT j.id, j.driver_offer_id, j.passenger_user_id, j.passenger_count,
                   CASE j.status
                       WHEN 'accepted' THEN 'confirmed'
                       WHEN 'awaiting_passenger' THEN 'awaiting_passenger'
                       WHEN 'confirmed' THEN 'confirmed'
                       WHEN 'declined' THEN 'declined'
                       WHEN 'cancelled' THEN 'cancelled'
                       WHEN 'expired' THEN 'expired'
                       ELSE 'pending'
                   END,
                   j.created_at
            FROM ride_join_requests j
            INNER JOIN driver_offers o ON o.id = j.driver_offer_id
            INNER JOIN users u ON u.id = j.passenger_user_id;
            DROP TABLE ride_join_requests;
            ALTER TABLE ride_join_requests_new RENAME TO ride_join_requests;
            CREATE INDEX IF NOT EXISTS idx_join_requests_offer
                ON ride_join_requests(driver_offer_id, status);
            """
        )
        _ensure_join_request_messages_table(conn)
    finally:
        conn.execute("PRAGMA foreign_keys=ON")


def init_db() -> None:
    with get_connection() as conn:
        conn.executescript(SCHEMA)
        for stmt in MIGRATION_SQL.strip().split(";"):
            s = stmt.strip()
            if s:
                try:
                    conn.execute(s)
                except sqlite3.OperationalError:
                    pass
        _migrate_join_requests_table(conn)
        _ensure_join_request_messages_table(conn)
        conn.execute(
            """
            UPDATE ride_join_requests SET status = 'confirmed'
            WHERE status = 'awaiting_passenger'
              AND id IN (
                SELECT join_request_id FROM active_rides
                WHERE join_request_id IS NOT NULL
              )
            """
        )
        _backfill_user_credits(conn)


def _backfill_user_credits(conn: sqlite3.Connection) -> None:
    """Ensure every user has a credit row (existing DBs before credits feature)."""
    conn.execute(
        """
        INSERT OR IGNORE INTO user_credits (user_id, balance)
        SELECT id, 20 FROM users
        WHERE id NOT IN (SELECT user_id FROM user_credits)
        """
    )


def new_session_token() -> str:
    return secrets.token_urlsafe(32)


# --- Data access ---


def insert_user(email: str, password: str, name: str) -> int:
    pw = hash_password(password)
    now = utc_now_iso()
    with get_connection() as conn:
        cur = conn.execute(
            "INSERT INTO users (email, password_hash, name, created_at) VALUES (?,?,?,?)",
            (email.strip().lower(), pw, name.strip(), now),
        )
        uid = int(cur.lastrowid)
        _adjust_credits(conn, uid, 20, "Créditos de boas-vindas")
        return uid


def get_user_by_email(email: str) -> sqlite3.Row | None:
    with get_connection() as conn:
        return conn.execute(
            "SELECT * FROM users WHERE email = ? COLLATE NOCASE",
            (email.strip().lower(),),
        ).fetchone()


def get_user_by_id(uid: int) -> sqlite3.Row | None:
    with get_connection() as conn:
        return conn.execute("SELECT * FROM users WHERE id = ?", (uid,)).fetchone()


def create_session(user_id: int) -> str:
    token = new_session_token()
    now = utc_now_iso()
    with get_connection() as conn:
        conn.execute(
            "INSERT INTO sessions (token, user_id, created_at) VALUES (?,?,?)",
            (token, user_id, now),
        )
    return token


def delete_session(token: str) -> None:
    with get_connection() as conn:
        conn.execute("DELETE FROM sessions WHERE token = ?", (token,))


def user_id_from_token(token: str | None) -> int | None:
    if not token:
        return None
    with get_connection() as conn:
        row = conn.execute(
            "SELECT user_id FROM sessions WHERE token = ?",
            (token,),
        ).fetchone()
        return int(row["user_id"]) if row else None


def insert_passenger_request(
    user_id: int,
    destination: str,
    passenger_count: int,
    origin_lat=None,
    origin_lng=None,
    origin_display: str | None = None,
    departure_time: str | None = None,
) -> int:
    norm = normalize_destination(destination)
    now = utc_now_iso()
    with get_connection() as conn:
        cur = conn.execute(
            """INSERT INTO passenger_requests
            (user_id, destination_norm, destination_display, passenger_count, status, created_at,
             origin_lat, origin_lng, origin_display, departure_time)
            VALUES (?,?,?,?, 'open', ?,?,?,?,?)""",
            (
                user_id,
                norm,
                destination.strip(),
                passenger_count,
                now,
                origin_lat,
                origin_lng,
                origin_display,
                departure_time,
            ),
        )
        return int(cur.lastrowid)


def get_user_average_rating(user_id: int) -> float | None:
    with get_connection() as conn:
        row = conn.execute(
            """
            SELECT AVG(stars) AS avg_stars, COUNT(*) AS cnt
            FROM user_ratings WHERE rated_user_id = ?
            """,
            (user_id,),
        ).fetchone()
    if not row or not row["cnt"]:
        return None
    return round(float(row["avg_stars"]), 1)


def _rating_fields(user_id: int) -> dict:
    avg = get_user_average_rating(user_id)
    return {
        "rating_avg": avg,
        "rating_display": f"{avg:.1f}" if avg is not None else "—",
    }


def insert_driver_offer(user_id: int, destination: str, available_seats: int, 
                        departure_time: str = None, description: str = None, # Novos argumentos
                        origin_lat=None, origin_lng=None, 
                        destination_lat=None, destination_lng=None,
                        vehicle_info: str = None) -> int:
    norm = normalize_destination(destination)
    now = utc_now_iso()
    status = "open" if available_seats > 0 else "full"
    with get_connection() as conn:
        cur = conn.execute(
            """INSERT INTO driver_offers
            (user_id, destination_norm, destination_display, available_seats, 
             departure_time, description, status, created_at, 
             origin_lat, origin_lng, destination_lat, destination_lng, vehicle_info)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (user_id, norm, destination.strip(), available_seats, 
             departure_time, description, status, now, 
             origin_lat, origin_lng, destination_lat, destination_lng, vehicle_info),
        )
        return int(cur.lastrowid)

def list_open_drivers_for_destination(destination: str,
                                      passenger_lat: float | None = None,
                                      passenger_lng: float | None = None,
                                      radius_m: int = 500) -> list[dict]:
    return list_open_drivers(destination, passenger_lat, passenger_lng, radius_m)


def list_open_passenger_requests_for_destination(destination: str) -> list[dict]:
    """Driver: passengers wanting a ride to the same destination."""
    return list_open_passenger_requests(destination)


""" 'Entirely' done by claude """
def list_open_drivers(destination: str | None = None,
                      passenger_lat: float | None = None,
                      passenger_lng: float | None = None,
                      radius_m: int = 500) -> list[dict]:
    args = []
    # Base da pesquisa: viagens abertas e com lugares
    where = "WHERE o.status = 'open' AND o.available_seats > 0"
    
    # SE NÃO houver coordenadas, filtramos por texto
    # SE HOUVER coordenadas (Mapa), ignoramos o filtro de texto para não falhar
    if not (passenger_lat and passenger_lng):
        if destination and destination.strip():
            where += " AND o.destination_norm = ?"
            args.append(normalize_destination(destination))

    with get_connection() as conn:
        rows = conn.execute(
            f"""
            SELECT o.id, o.destination_display, o.available_seats, o.created_at,
                   o.origin_lat, o.origin_lng, o.destination_lat, o.destination_lng,
                   o.departure_time, o.description,
                   u.id AS driver_user_id, u.name AS driver_name, u.email AS driver_email
            FROM driver_offers o
            JOIN users u ON u.id = o.user_id
            {where}
            ORDER BY o.created_at DESC
            """,
            tuple(args),
        ).fetchall()
    
    # Se o passageiro usou o MAPA, aplicamos o filtro de RAIO (Distância)
    active = [dict(r) for r in rows if is_not_expired(r["created_at"])]
    if passenger_lat and passenger_lng:
        return _apply_radius_filter(
            active,
            passenger_lat, passenger_lng, radius_m,
            lat_key='destination_lat', lng_key='destination_lng' # Filtra pela chegada!
        )
    
    return active

def list_open_passenger_requests(destination: str | None = None) -> list[dict]:
    """Community board: list currently open passenger requests."""
    args: tuple[str, ...] = ()
    where = "WHERE r.status = 'open'"
    if destination and destination.strip():
        where += " AND r.destination_norm = ?"
        args = (normalize_destination(destination),)

    with get_connection() as conn:
        rows = conn.execute(
            f"""
            SELECT r.id, r.destination_display, r.passenger_count, r.created_at,
                   u.id AS passenger_user_id, u.name AS passenger_name, u.email AS passenger_email
            FROM passenger_requests r
            JOIN users u ON u.id = r.user_id
            {where}
            ORDER BY r.created_at DESC
            """,
            args,
        ).fetchall()
    return [dict(r) for r in rows if is_not_expired(r["created_at"])]


def book_driver_offer(offer_id: int, passenger_user_id: int) -> dict:
    now = utc_now_iso()
    with get_connection() as conn:
        offer = conn.execute(
            """
            SELECT o.id, o.user_id AS driver_user_id, o.status, o.destination_display, o.available_seats
            FROM driver_offers o
            WHERE o.id = ?
            """,
            (offer_id,),
        ).fetchone()
        if not offer:
            raise ValueError("Driver offer not found")
        if offer["driver_user_id"] == passenger_user_id:
            raise ValueError("You cannot book your own ride")

        existing = conn.execute(
            "SELECT id FROM ride_bookings WHERE driver_offer_id = ?",
            (offer_id,),
        ).fetchone()
        if existing:
            raise ValueError("Driver offer already booked")

        if offer['status'] != 'open' or int(offer['available_seats']) <= 0:
            raise ValueError("Driver offer is not open")

        cur = conn.execute(
            """
            INSERT INTO ride_bookings (driver_offer_id, passenger_request_id, booked_by_user_id, created_at)
            VALUES (?, NULL, ?, ?)
            """,
            (offer_id, passenger_user_id, now),
        )
        conn.execute(
            "UPDATE driver_offers SET status = 'full', available_seats = 0 WHERE id = ?",
            (offer_id,),
        )
        return {"booking_id": int(cur.lastrowid), "offer_id": offer_id}


def book_passenger_request(request_id: int, driver_user_id: int) -> dict:
    now = utc_now_iso()
    with get_connection() as conn:
        req = conn.execute(
            """
            SELECT r.id, r.user_id AS passenger_user_id, r.status
            FROM passenger_requests r
            WHERE r.id = ?
            """,
            (request_id,),
        ).fetchone()
        if not req:
            raise ValueError("Passenger request not found")
        if req["passenger_user_id"] == driver_user_id:
            raise ValueError("You cannot book your own passenger request")

        existing = conn.execute(
            "SELECT id FROM ride_bookings WHERE passenger_request_id = ?",
            (request_id,),
        ).fetchone()
        if existing:
            raise ValueError("Passenger request already booked")

        if req['status'] != 'open':
            raise ValueError("Passenger request is not open")

        cur = conn.execute(
            """
            INSERT INTO ride_bookings (driver_offer_id, passenger_request_id, booked_by_user_id, created_at)
            VALUES (NULL, ?, ?, ?)
            """,
            (request_id, driver_user_id, now),
        )
        conn.execute(
            "UPDATE passenger_requests SET status = 'fulfilled' WHERE id = ?",
            (request_id,),
        )
        return {"booking_id": int(cur.lastrowid), "request_id": request_id}

def list_community_drivers(destination: str | None = None,
                           passenger_lat: float | None = None,
                           passenger_lng: float | None = None,
                           radius_m: int = 500) -> list[dict]:
    args: tuple[str, ...] = ()
    where = "WHERE o.status IN ('open', 'full')"
    if destination and destination.strip():
        where += " AND o.destination_norm = ?"
        args = (normalize_destination(destination),)

    with get_connection() as conn:
        rows = conn.execute(
            f"""
            SELECT o.id, o.destination_display, o.available_seats, o.status, o.created_at,
                   o.origin_lat, o.origin_lng,
                   o.departure_time, o.description, -- ADICIONA ESTAS DUAS COLUNAS AQUI
                   u.id AS driver_user_id, u.name AS driver_name, u.email AS driver_email,
                   b.id AS booking_id, b.created_at AS booked_at, b.booked_by_user_id,
                   bu.name AS booked_by_name, bu.email AS booked_by_email
            FROM driver_offers o
            JOIN users u ON u.id = o.user_id
            LEFT JOIN ride_bookings b ON b.driver_offer_id = o.id
            LEFT JOIN users bu ON bu.id = b.booked_by_user_id
            {where}
            ORDER BY o.created_at DESC
            """,
            args,
        ).fetchall()
    return _apply_radius_filter(
        [dict(r) for r in rows],
        passenger_lat, passenger_lng, radius_m,
        lat_key='origin_lat', lng_key='origin_lng'
    )

def list_community_passengers(destination: str | None = None) -> list[dict]:
    args: tuple[str, ...] = ()
    where = "WHERE r.status IN ('open', 'fulfilled')"
    if destination and destination.strip():
        where += " AND r.destination_norm = ?"
        args = (normalize_destination(destination),)
    with get_connection() as conn:
        rows = conn.execute(
            f"""
            SELECT r.id, r.destination_display, r.passenger_count, r.status, r.created_at,
                   u.id AS passenger_user_id, u.name AS passenger_name, u.email AS passenger_email,
                   b.id AS booking_id, b.created_at AS booked_at, b.booked_by_user_id,
                   bu.name AS booked_by_name, bu.email AS booked_by_email
            FROM passenger_requests r
            JOIN users u ON u.id = r.user_id
            LEFT JOIN ride_bookings b ON b.passenger_request_id = r.id
            LEFT JOIN users bu ON bu.id = b.booked_by_user_id
            {where}
            ORDER BY r.created_at DESC
            """,
            args,
        ).fetchall()
    return [dict(r) for r in rows]


def get_database_schema() -> dict:
    """Expose table/column metadata for in-app diagnostics."""
    with get_connection() as conn:
        tables = conn.execute(
            """
            SELECT name
            FROM sqlite_master
            WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
            ORDER BY name
            """
        ).fetchall()
        schema: dict[str, list[dict]] = {}
        for table in tables:
            table_name = table["name"]
            columns = conn.execute(f"PRAGMA table_info({table_name})").fetchall()
            schema[table_name] = [
                {
                    "name": c["name"],
                    "type": c["type"],
                    "not_null": bool(c["notnull"]),
                    "primary_key": bool(c["pk"]),
                    "default": c["dflt_value"],
                }
                for c in columns
            ]
    return {"tables": schema}

"""Haversine function to find the distance between 2 points on earth"""
def haversine_meters(lat1, lng1, lat2, lng2) -> float:
    R = 6_371_000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (math.sin(dphi/2)**2 +
         math.cos(phi1) * math.cos(phi2) * math.sin(dlng/2)**2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

def _apply_radius_filter(rows, passenger_lat, passenger_lng,
                         radius_m, lat_key, lng_key) -> list:
    if passenger_lat is None or passenger_lng is None:
        return rows
    return [
        r for r in rows
        if r.get(lat_key) and haversine_meters(
            passenger_lat, passenger_lng,
            r[lat_key], r[lng_key]
        ) <= radius_m
    ]


# --- Ride join requests & active rides ---


def _confirmed_seats_for_offer(conn: sqlite3.Connection, driver_offer_id: int) -> int:
    row = conn.execute(
        """
        SELECT COALESCE(SUM(passenger_count), 0) AS seats
        FROM ride_join_requests
        WHERE driver_offer_id = ? AND status = 'confirmed'
        """,
        (driver_offer_id,),
    ).fetchone()
    return int(row["seats"] or 0)


def create_join_request(
    driver_offer_id: int,
    passenger_user_id: int,
    passenger_count: int = 1,
    origin_display: str | None = None,
    destination_display: str | None = None,
    departure_time: str | None = None,
) -> dict:
    now = utc_now_iso()
    with get_connection() as conn:
        offer = conn.execute(
            """
            SELECT id, user_id, status, available_seats, destination_display,
                   departure_time, created_at
            FROM driver_offers WHERE id = ?
            """,
            (driver_offer_id,),
        ).fetchone()
        if not offer:
            raise ValueError("Driver offer not found")
        if int(offer["user_id"]) == passenger_user_id:
            raise ValueError("You cannot request your own ride")
        if not is_not_expired(offer["created_at"]):
            raise ValueError("Driver offer has expired")
        if offer["status"] not in ("open",) or int(offer["available_seats"]) < passenger_count:
            raise ValueError("Driver offer is not available")

        confirmed = _confirmed_seats_for_offer(conn, driver_offer_id)
        if confirmed + passenger_count > int(offer["available_seats"]):
            raise ValueError("Not enough seats available")

        pending = conn.execute(
            """
            SELECT id FROM ride_join_requests
            WHERE driver_offer_id = ? AND passenger_user_id = ?
              AND status IN ('pending', 'awaiting_passenger')
            """,
            (driver_offer_id, passenger_user_id),
        ).fetchone()
        if pending:
            raise ValueError("You already have a pending request for this ride")

        balance = _adjust_credits(
            conn, passenger_user_id, -CREDITS_BOOKING_COST, "Reserva de boleia"
        )

        dest = destination_display or offer["destination_display"]
        dep = departure_time or offer["departure_time"]
        cur = conn.execute(
            """
            INSERT INTO ride_join_requests
            (driver_offer_id, passenger_user_id, passenger_count, origin_display,
             destination_display, departure_time, status, created_at)
            VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)
            """,
            (
                driver_offer_id,
                passenger_user_id,
                passenger_count,
                origin_display,
                dest,
                dep,
                now,
            ),
        )
        return {"id": int(cur.lastrowid), "credits_balance": balance}


def list_join_requests_for_offer(driver_offer_id: int, driver_user_id: int) -> list[dict]:
    with get_connection() as conn:
        offer = conn.execute(
            "SELECT user_id FROM driver_offers WHERE id = ?", (driver_offer_id,)
        ).fetchone()
        if not offer:
            raise ValueError("Driver offer not found")
        if int(offer["user_id"]) != driver_user_id:
            raise ValueError("Not your offer")

        rows = conn.execute(
            """
            SELECT j.id, j.passenger_count, j.status, j.created_at,
                   j.origin_display, j.destination_display, j.departure_time,
                   u.id AS passenger_user_id, u.name AS passenger_name, u.email AS passenger_email
            FROM ride_join_requests j
            JOIN users u ON u.id = j.passenger_user_id
            WHERE j.driver_offer_id = ? AND j.status IN ('pending', 'awaiting_passenger')
            ORDER BY j.created_at ASC
            """,
            (driver_offer_id,),
        ).fetchall()

    result = []
    for r in rows:
        d = dict(r)
        if not is_not_expired(d["created_at"]):
            continue
        d.update(_rating_fields(int(d["passenger_user_id"])))
        result.append(d)
    return result


def list_my_driver_offers_with_pending(user_id: int) -> list[dict]:
    with get_connection() as conn:
        offers = conn.execute(
            """
            SELECT o.id, o.destination_display, o.available_seats, o.departure_time,
                   o.description, o.vehicle_info, o.status, o.created_at
            FROM driver_offers o
            WHERE o.user_id = ? AND o.status = 'open'
            ORDER BY o.created_at DESC
            """,
            (user_id,),
        ).fetchall()

    out = []
    for o in offers:
        oid = int(o["id"])
        pending = list_join_requests_for_offer(oid, user_id)
        if pending:
            item = dict(o)
            item["pending_requests"] = pending
            item["pending_count"] = len(pending)
            out.append(item)
    return out


def respond_join_request(request_id: int, driver_user_id: int, accept: bool) -> dict:
    now = utc_now_iso()
    with get_connection() as conn:
        req = conn.execute(
            """
            SELECT j.id, j.driver_offer_id, j.passenger_user_id, j.passenger_count, j.status,
                   o.user_id AS driver_user_id, o.available_seats, o.status AS offer_status
            FROM ride_join_requests j
            JOIN driver_offers o ON o.id = j.driver_offer_id
            WHERE j.id = ?
            """,
            (request_id,),
        ).fetchone()
        if not req:
            raise ValueError("Join request not found")
        if int(req["driver_user_id"]) != driver_user_id:
            raise ValueError("Not authorized")
        if req["status"] != "pending":
            raise ValueError("Request is no longer pending")

        if not accept:
            conn.execute(
                "UPDATE ride_join_requests SET status = 'declined' WHERE id = ?",
                (request_id,),
            )
            return {"request_id": request_id, "status": "declined"}

        if req["offer_status"] not in ("open",):
            raise ValueError("Offer is no longer open")
        confirmed = _confirmed_seats_for_offer(conn, int(req["driver_offer_id"]))
        awaiting = conn.execute(
            """
            SELECT COALESCE(SUM(passenger_count), 0) FROM ride_join_requests
            WHERE driver_offer_id = ? AND status = 'awaiting_passenger'
            """,
            (req["driver_offer_id"],),
        ).fetchone()[0]
        if confirmed + awaiting + int(req["passenger_count"]) > int(req["available_seats"]):
            raise ValueError("Not enough seats")

        conn.execute(
            "UPDATE ride_join_requests SET status = 'awaiting_passenger' WHERE id = ?",
            (request_id,),
        )
        return {"request_id": request_id, "status": "awaiting_passenger"}


def passenger_respond_join_request(request_id: int, passenger_user_id: int, accept: bool) -> dict:
    now = utc_now_iso()
    with get_connection() as conn:
        req = conn.execute(
            """
            SELECT j.id, j.driver_offer_id, j.passenger_user_id, j.passenger_count, j.status,
                   o.user_id AS driver_user_id, o.available_seats, o.status AS offer_status
            FROM ride_join_requests j
            JOIN driver_offers o ON o.id = j.driver_offer_id
            WHERE j.id = ?
            """,
            (request_id,),
        ).fetchone()
        if not req:
            raise ValueError("Join request not found")
        if int(req["passenger_user_id"]) != passenger_user_id:
            raise ValueError("Not authorized")

        existing_ride = conn.execute(
            "SELECT id, status FROM active_rides WHERE join_request_id = ?",
            (request_id,),
        ).fetchone()

        if req["status"] == "confirmed":
            if existing_ride:
                return {
                    "request_id": request_id,
                    "status": "confirmed",
                    "active_ride_id": int(existing_ride["id"]),
                }
            raise ValueError("Request already confirmed")

        if req["status"] != "awaiting_passenger":
            raise ValueError("Request is not awaiting passenger confirmation")

        if not accept:
            conn.execute(
                "UPDATE ride_join_requests SET status = 'declined' WHERE id = ?",
                (request_id,),
            )
            return {"request_id": request_id, "status": "declined"}

        confirmed = _confirmed_seats_for_offer(conn, int(req["driver_offer_id"]))
        if confirmed + int(req["passenger_count"]) > int(req["available_seats"]):
            raise ValueError("Not enough seats left")

        conn.execute(
            "UPDATE ride_join_requests SET status = 'confirmed' WHERE id = ?",
            (request_id,),
        )

        if existing_ride:
            # Viagem criada pelo fluxo antigo (aceite imediato do condutor).
            ride_id = int(existing_ride["id"])
        else:
            cur = conn.execute(
                """
                INSERT INTO active_rides
                (driver_offer_id, join_request_id, driver_user_id, passenger_user_id,
                 status, driver_in_car, passenger_in_car, created_at)
                VALUES (?, ?, ?, ?, 'matched', 0, 0, ?)
                """,
                (
                    req["driver_offer_id"],
                    request_id,
                    req["driver_user_id"],
                    req["passenger_user_id"],
                    now,
                ),
            )
            ride_id = int(cur.lastrowid)

        new_confirmed = confirmed + int(req["passenger_count"])
        seats_left = int(req["available_seats"]) - new_confirmed
        offer_status = "full" if seats_left <= 0 else "open"
        conn.execute(
            "UPDATE driver_offers SET status = ? WHERE id = ?",
            (offer_status, req["driver_offer_id"]),
        )

        return {
            "request_id": request_id,
            "status": "confirmed",
            "active_ride_id": ride_id,
        }


def get_active_ride_for_user(user_id: int) -> dict | None:
    with get_connection() as conn:
        row = conn.execute(
            """
            SELECT ar.*, o.destination_display, o.departure_time, o.description AS origin_description,
                    o.vehicle_info AS vehicle_display,
                    o.available_seats,
                   du.name AS driver_name, du.email AS driver_email,
                   pu.name AS passenger_name, pu.email AS passenger_email
            FROM active_rides ar
            JOIN driver_offers o ON o.id = ar.driver_offer_id
            JOIN users du ON du.id = ar.driver_user_id
            JOIN users pu ON pu.id = ar.passenger_user_id
            WHERE ar.status IN ('matched', 'in_progress')
              AND (ar.driver_user_id = ? OR ar.passenger_user_id = ?)
            ORDER BY ar.created_at DESC
            LIMIT 1
            """,
            (user_id, user_id),
        ).fetchone()
    if not row:
        return None

    d = dict(row)
    d["is_driver"] = int(d["driver_user_id"]) == user_id
    d["is_passenger"] = int(d["passenger_user_id"]) == user_id
    d.update(_rating_fields(int(d["driver_user_id"])))
    d["driver_rating_avg"] = d.pop("rating_avg")
    d["driver_rating_display"] = d.pop("rating_display")
    p_rating = _rating_fields(int(d["passenger_user_id"]))
    d["passenger_rating_avg"] = p_rating["rating_avg"]
    d["passenger_rating_display"] = p_rating["rating_display"]
    d["vehicle_display"] = d.get("vehicle_display") or d.get("origin_description") or "Veículo"
    d["needs_rating"] = False
    if d["status"] == "completed":
        d["needs_rating"] = not _user_rated_ride(int(d["id"]), user_id)
    return d


def _user_rated_ride(active_ride_id: int, user_id: int) -> bool:
    with get_connection() as conn:
        row = conn.execute(
            "SELECT id FROM user_ratings WHERE active_ride_id = ? AND rater_user_id = ?",
            (active_ride_id, user_id),
        ).fetchone()
    return row is not None


def confirm_in_car(active_ride_id: int, user_id: int) -> dict:
    now = utc_now_iso()
    with get_connection() as conn:
        ride = conn.execute("SELECT * FROM active_rides WHERE id = ?", (active_ride_id,)).fetchone()
        if not ride:
            raise ValueError("Active ride not found")
        if ride["status"] not in ("matched", "in_progress"):
            raise ValueError("Ride is not active")

        driver_in = bool(ride["driver_in_car"])
        passenger_in = bool(ride["passenger_in_car"])

        if int(ride["driver_user_id"]) == user_id:
            driver_in = True
        elif int(ride["passenger_user_id"]) == user_id:
            passenger_in = True
        else:
            raise ValueError("Not a participant in this ride")

        status = ride["status"]
        started_at = ride["started_at"]
        if driver_in and passenger_in:
            status = "in_progress"
            started_at = started_at or now

        conn.execute(
            """
            UPDATE active_rides
            SET driver_in_car = ?, passenger_in_car = ?, status = ?, started_at = ?
            WHERE id = ?
            """,
            (int(driver_in), int(passenger_in), status, started_at, active_ride_id),
        )
    return get_active_ride_for_user(user_id) or {}


def complete_ride(active_ride_id: int, user_id: int) -> dict:
    now = utc_now_iso()
    with get_connection() as conn:
        ride = conn.execute("SELECT * FROM active_rides WHERE id = ?", (active_ride_id,)).fetchone()
        if not ride:
            raise ValueError("Active ride not found")
        if int(ride["driver_user_id"]) != user_id and int(ride["passenger_user_id"]) != user_id:
            raise ValueError("Not a participant in this ride")
        if ride["status"] != "in_progress":
            raise ValueError("Ride must be in progress to complete")

        conn.execute(
            "UPDATE active_rides SET status = 'completed', completed_at = ? WHERE id = ?",
            (now, active_ride_id),
        )
        _adjust_credits(conn, int(ride["driver_user_id"]), CREDITS_RIDE_COMPLETE, "Viagem concluída (condutor)")
        _adjust_credits(conn, int(ride["passenger_user_id"]), CREDITS_RIDE_COMPLETE, "Viagem concluída (passageiro)")
    result = get_active_ride_for_user(user_id)
    if result and result.get("status") == "completed":
        result["needs_rating"] = not _user_rated_ride(active_ride_id, user_id)
    return result or {"active_ride_id": active_ride_id, "status": "completed", "needs_rating": True}


def add_ride_message(active_ride_id: int, sender_user_id: int, body: str) -> dict:
    text = body.strip()
    if not text:
        raise ValueError("Message cannot be empty")
    now = utc_now_iso()
    with get_connection() as conn:
        ride = conn.execute("SELECT * FROM active_rides WHERE id = ?", (active_ride_id,)).fetchone()
        if not ride:
            raise ValueError("Active ride not found")
        if int(ride["driver_user_id"]) != sender_user_id and int(ride["passenger_user_id"]) != sender_user_id:
            raise ValueError("Not a participant in this ride")
        if ride["status"] not in ("matched", "in_progress"):
            raise ValueError("Chat is only available during an active ride")

        cur = conn.execute(
            """
            INSERT INTO ride_messages (active_ride_id, sender_user_id, body, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (active_ride_id, sender_user_id, text, now),
        )
        msg_id = int(cur.lastrowid)
        sender = conn.execute("SELECT name FROM users WHERE id = ?", (sender_user_id,)).fetchone()
    return {
        "id": msg_id,
        "active_ride_id": active_ride_id,
        "sender_user_id": sender_user_id,
        "sender_name": sender["name"] if sender else "",
        "body": text,
        "created_at": now,
    }


def list_ride_messages(active_ride_id: int, user_id: int) -> list[dict]:
    with get_connection() as conn:
        ride = conn.execute("SELECT * FROM active_rides WHERE id = ?", (active_ride_id,)).fetchone()
        if not ride:
            raise ValueError("Active ride not found")
        if int(ride["driver_user_id"]) != user_id and int(ride["passenger_user_id"]) != user_id:
            raise ValueError("Not a participant in this ride")

        rows = conn.execute(
            """
            SELECT m.id, m.active_ride_id, m.sender_user_id, m.body, m.created_at,
                   u.name AS sender_name
            FROM ride_messages m
            JOIN users u ON u.id = m.sender_user_id
            WHERE m.active_ride_id = ?
            ORDER BY m.created_at ASC
            """,
            (active_ride_id,),
        ).fetchall()
    return [dict(r) for r in rows]


def _average_criteria(criteria: dict[str, int]) -> int:
    vals = [int(criteria[k]) for k in RATING_CRITERIA_KEYS if k in criteria]
    if not vals:
        raise ValueError("At least one rating criterion is required")
    return max(1, min(5, round(sum(vals) / len(vals))))


def submit_rating(
    active_ride_id: int,
    rater_user_id: int,
    stars: int | None = None,
    criteria: dict[str, int] | None = None,
) -> dict:
    if criteria:
        stars = _average_criteria(criteria)
    if stars is None or stars < 1 or stars > 5:
        raise ValueError("Rating must be between 1 and 5")
    now = utc_now_iso()
    import json

    criteria_json = json.dumps(criteria) if criteria else None
    with get_connection() as conn:
        ride = conn.execute("SELECT * FROM active_rides WHERE id = ?", (active_ride_id,)).fetchone()
        if not ride:
            raise ValueError("Active ride not found")
        if ride["status"] != "completed":
            raise ValueError("Can only rate completed rides")

        if int(ride["driver_user_id"]) == rater_user_id:
            rated_id = int(ride["passenger_user_id"])
        elif int(ride["passenger_user_id"]) == rater_user_id:
            rated_id = int(ride["driver_user_id"])
        else:
            raise ValueError("Not a participant in this ride")

        conn.execute(
            """
            INSERT INTO user_ratings
            (active_ride_id, rater_user_id, rated_user_id, stars, criteria_json, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (active_ride_id, rater_user_id, rated_id, stars, criteria_json, now),
        )
    return {
        "active_ride_id": active_ride_id,
        "rated_user_id": rated_id,
        "stars": stars,
        "criteria": criteria,
    }


def get_completed_ride_needing_rating(user_id: int) -> dict | None:
    with get_connection() as conn:
        row = conn.execute(
            """
            SELECT ar.*, o.destination_display,
                   du.name AS driver_name, pu.name AS passenger_name
            FROM active_rides ar
            JOIN driver_offers o ON o.id = ar.driver_offer_id
            JOIN users du ON du.id = ar.driver_user_id
            JOIN users pu ON pu.id = ar.passenger_user_id
            WHERE ar.status = 'completed'
              AND (ar.driver_user_id = ? OR ar.passenger_user_id = ?)
            ORDER BY ar.completed_at DESC
            LIMIT 1
            """,
            (user_id, user_id),
        ).fetchone()
    if not row:
        return None
    if _user_rated_ride(int(row["id"]), user_id):
        return None
    d = dict(row)
    d["is_driver"] = int(d["driver_user_id"]) == user_id
    if d["is_driver"]:
        d["rate_target_name"] = d["passenger_name"]
        d["rate_target_user_id"] = d["passenger_user_id"]
    else:
        d["rate_target_name"] = d["driver_name"]
        d["rate_target_user_id"] = d["driver_user_id"]
    return d


def _ensure_credit_row(conn: sqlite3.Connection, user_id: int) -> None:
    conn.execute(
        "INSERT OR IGNORE INTO user_credits (user_id, balance) VALUES (?, 0)",
        (user_id,),
    )


def _adjust_credits(conn: sqlite3.Connection, user_id: int, delta: int, description: str) -> int:
    _ensure_credit_row(conn, user_id)
    row = conn.execute(
        "SELECT balance FROM user_credits WHERE user_id = ?", (user_id,)
    ).fetchone()
    balance = int(row["balance"]) + delta
    if balance < 0:
        raise ValueError("Créditos insuficientes")
    conn.execute("UPDATE user_credits SET balance = ? WHERE user_id = ?", (balance, user_id))
    conn.execute(
        """
        INSERT INTO credit_transactions (user_id, amount_delta, description, created_at)
        VALUES (?, ?, ?, ?)
        """,
        (user_id, delta, description, utc_now_iso()),
    )
    return balance


def get_credit_balance(user_id: int) -> int:
    with get_connection() as conn:
        _ensure_credit_row(conn, user_id)
        row = conn.execute(
            "SELECT balance FROM user_credits WHERE user_id = ?", (user_id,)
        ).fetchone()
    return int(row["balance"]) if row else 0


def list_credit_transactions(user_id: int, limit: int = 50) -> list[dict]:
    with get_connection() as conn:
        rows = conn.execute(
            """
            SELECT id, amount_delta, description, created_at
            FROM credit_transactions
            WHERE user_id = ?
            ORDER BY created_at DESC
            LIMIT ?
            """,
            (user_id, limit),
        ).fetchall()
    return [dict(r) for r in rows]


def set_user_vehicle(user_id: int, vehicle_info: str) -> None:
    with get_connection() as conn:
        conn.execute(
            "UPDATE users SET vehicle_info = ? WHERE id = ?",
            (vehicle_info.strip(), user_id),
        )


def get_user_profile(user_id: int) -> dict:
    row = get_user_by_id(user_id)
    if not row:
        raise ValueError("User not found")
    d = dict(row)
    d.pop("password_hash", None)
    d["credits_balance"] = get_credit_balance(user_id)
    d.update(_rating_fields(user_id))
    d["vehicle_info"] = d.get("vehicle_info") or ""
    return d


def list_reviews_for_user(user_id: int, limit: int = 20) -> list[dict]:
    import json

    with get_connection() as conn:
        rows = conn.execute(
            """
            SELECT r.stars, r.criteria_json, r.created_at, u.name AS rater_name
            FROM user_ratings r
            JOIN users u ON u.id = r.rater_user_id
            WHERE r.rated_user_id = ?
            ORDER BY r.created_at DESC
            LIMIT ?
            """,
            (user_id, limit),
        ).fetchall()
    out = []
    for r in rows:
        item = dict(r)
        raw = item.pop("criteria_json", None)
        if raw:
            try:
                item["criteria"] = json.loads(raw)
            except json.JSONDecodeError:
                item["criteria"] = None
        out.append(item)
    return out


def _join_request_row_to_dict(r: sqlite3.Row, viewer_id: int) -> dict:
    d = dict(r)
    if not is_not_expired(d["created_at"]):
        return None
    d.update(_rating_fields(int(d.get("driver_user_id") or d.get("passenger_user_id") or 0)))
    d["chat_available"] = d["status"] in ("pending", "awaiting_passenger", "confirmed")
    d["needs_passenger_confirmation"] = (
        d["status"] == "awaiting_passenger" and int(d["passenger_user_id"]) == viewer_id
    )
    return d


def list_passenger_join_requests(passenger_user_id: int) -> list[dict]:
    with get_connection() as conn:
        rows = conn.execute(
            """
            SELECT j.*, o.destination_display AS offer_destination,
                   du.name AS driver_name, du.id AS driver_user_id
            FROM ride_join_requests j
            JOIN driver_offers o ON o.id = j.driver_offer_id
            JOIN users du ON du.id = o.user_id
            WHERE j.passenger_user_id = ?
              AND j.status NOT IN ('declined', 'cancelled', 'expired')
            ORDER BY j.created_at DESC
            """,
            (passenger_user_id,),
        ).fetchall()
    out = []
    for r in rows:
        item = _join_request_row_to_dict(r, passenger_user_id)
        if item:
            out.append(item)
    return out


def list_driver_incoming_join_requests(driver_user_id: int) -> list[dict]:
    with get_connection() as conn:
        rows = conn.execute(
            """
            SELECT j.*, o.destination_display AS offer_destination,
                   o.departure_time AS offer_departure_time,
                   pu.name AS passenger_name, pu.id AS passenger_user_id
            FROM ride_join_requests j
            JOIN driver_offers o ON o.id = j.driver_offer_id
            JOIN users pu ON pu.id = j.passenger_user_id
            WHERE o.user_id = ?
              AND j.status IN ('pending', 'awaiting_passenger')
            ORDER BY j.created_at DESC
            """,
            (driver_user_id,),
        ).fetchall()
    out = []
    for r in rows:
        item = _join_request_row_to_dict(r, driver_user_id)
        if item:
            out.append(item)
    return out


def add_join_request_message(join_request_id: int, sender_user_id: int, body: str) -> dict:
    text = body.strip()
    if not text:
        raise ValueError("Message cannot be empty")
    now = utc_now_iso()
    with get_connection() as conn:
        req = conn.execute(
            """
            SELECT j.id, j.status, j.passenger_user_id, o.user_id AS driver_user_id
            FROM ride_join_requests j
            JOIN driver_offers o ON o.id = j.driver_offer_id
            WHERE j.id = ?
            """,
            (join_request_id,),
        ).fetchone()
        if not req:
            raise ValueError("Join request not found")
        if sender_user_id not in (int(req["passenger_user_id"]), int(req["driver_user_id"])):
            raise ValueError("Not authorized")
        if req["status"] not in ("pending", "awaiting_passenger", "confirmed"):
            raise ValueError("Chat is not available for this request")

        cur = conn.execute(
            """
            INSERT INTO join_request_messages (join_request_id, sender_user_id, body, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (join_request_id, sender_user_id, text, now),
        )
        sender = conn.execute("SELECT name FROM users WHERE id = ?", (sender_user_id,)).fetchone()
    return {
        "id": int(cur.lastrowid),
        "join_request_id": join_request_id,
        "sender_name": sender["name"] if sender else "",
        "body": text,
        "created_at": now,
    }


def list_join_request_messages(join_request_id: int, user_id: int) -> list[dict]:
    with get_connection() as conn:
        req = conn.execute(
            """
            SELECT j.passenger_user_id, o.user_id AS driver_user_id, j.status
            FROM ride_join_requests j
            JOIN driver_offers o ON o.id = j.driver_offer_id
            WHERE j.id = ?
            """,
            (join_request_id,),
        ).fetchone()
        if not req:
            raise ValueError("Join request not found")
        if user_id not in (int(req["passenger_user_id"]), int(req["driver_user_id"])):
            raise ValueError("Not authorized")

        rows = conn.execute(
            """
            SELECT m.id, m.body, m.created_at, u.name AS sender_name, m.sender_user_id
            FROM join_request_messages m
            JOIN users u ON u.id = m.sender_user_id
            WHERE m.join_request_id = ?
            ORDER BY m.created_at ASC
            """,
            (join_request_id,),
        ).fetchall()
    return [dict(r) for r in rows]


def expire_stale_records() -> None:
    """Mark join requests and offers older than 12h as expired / hide from listings."""
    cutoff = (datetime.now(timezone.utc) - timedelta(hours=REQUEST_EXPIRY_HOURS)).replace(microsecond=0).isoformat()
    with get_connection() as conn:
        conn.execute(
            """
            UPDATE ride_join_requests SET status = 'expired'
            WHERE status IN ('pending', 'awaiting_passenger')
              AND created_at < ?
            """,
            (cutoff,),
        )
        conn.execute(
            """
            UPDATE passenger_requests SET status = 'cancelled'
            WHERE status = 'open' AND created_at < ?
            """,
            (cutoff,),
        )
        conn.execute(
            """
            UPDATE driver_offers SET status = 'cancelled'
            WHERE status = 'open' AND created_at < ?
            """,
            (cutoff,),
        )

