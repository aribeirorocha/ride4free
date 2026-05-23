"""SQLite persistence for Ride4Free (local dev)."""

from __future__ import annotations

import hashlib
import secrets
import sqlite3
import math
from contextlib import contextmanager
from datetime import datetime, timezone
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
    destination_norm TEXT NOT NULL,
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
"""


def init_db() -> None:
    with get_connection() as conn:
        conn.executescript(SCHEMA)


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
        return int(cur.lastrowid)


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


def insert_passenger_request(user_id: int, destination: str, passenger_count: int, origin_lat=None, origin_lng=None) -> int:
    norm = normalize_destination(destination)
    now = utc_now_iso()
    with get_connection() as conn:
        cur = conn.execute(
            """INSERT INTO passenger_requests
            (user_id, destination_norm, destination_display, passenger_count, status, created_at, origin_lat, origin_lng)
            VALUES (?,?,?,?, 'open', ?,?,?)""",
            (user_id, norm, destination.strip(), passenger_count, now, origin_lat, origin_lng),
        )
        return int(cur.lastrowid)


def insert_driver_offer(user_id: int, destination: str, available_seats: int, 
                        departure_time: str = None, description: str = None, # Novos argumentos
                        origin_lat=None, origin_lng=None, 
                        destination_lat=None, destination_lng=None) -> int:
    norm = normalize_destination(destination)
    now = utc_now_iso()
    status = "open" if available_seats > 0 else "full"
    with get_connection() as conn:
        cur = conn.execute(
            """INSERT INTO driver_offers
            (user_id, destination_norm, destination_display, available_seats, 
             departure_time, description, status, created_at, 
             origin_lat, origin_lng, destination_lat, destination_lng)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?)""",
            (user_id, norm, destination.strip(), available_seats, 
             departure_time, description, status, now, 
             origin_lat, origin_lng, destination_lat, destination_lng),
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
    if passenger_lat and passenger_lng:
        return _apply_radius_filter(
            [dict(r) for r in rows],
            passenger_lat, passenger_lng, radius_m,
            lat_key='destination_lat', lng_key='destination_lng' # Filtra pela chegada!
        )
    
    return [dict(r) for r in rows]

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
    return [dict(r) for r in rows]


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

