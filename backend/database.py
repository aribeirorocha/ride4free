"""
SQLite persistence for Ride4Free (local dev). Replace with Firebase/Firestore
or Cloud SQL when moving to Firebase Hosting + backend.
"""

from __future__ import annotations

import hashlib
import secrets
import sqlite3
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
    destination_norm TEXT NOT NULL,
    destination_display TEXT NOT NULL,
    available_seats INTEGER NOT NULL CHECK (available_seats >= 0),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'full', 'cancelled')),
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_driver_dest ON driver_offers(destination_norm, status);
"""


def init_db() -> None:
    with get_connection() as conn:
        conn.executescript(SCHEMA)


def new_session_token() -> str:
    return secrets.token_urlsafe(32)


# --- Data access (swap implementation when moving to Firebase) ---


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


def insert_passenger_request(user_id: int, destination: str, passenger_count: int) -> int:
    norm = normalize_destination(destination)
    now = utc_now_iso()
    with get_connection() as conn:
        cur = conn.execute(
            """INSERT INTO passenger_requests
            (user_id, destination_norm, destination_display, passenger_count, status, created_at)
            VALUES (?,?,?,?, 'open', ?)""",
            (user_id, norm, destination.strip(), passenger_count, now),
        )
        return int(cur.lastrowid)


def insert_driver_offer(user_id: int, destination: str, available_seats: int) -> int:
    norm = normalize_destination(destination)
    now = utc_now_iso()
    status = "open" if available_seats > 0 else "full"
    with get_connection() as conn:
        cur = conn.execute(
            """INSERT INTO driver_offers
            (user_id, destination_norm, destination_display, available_seats, status, created_at)
            VALUES (?,?,?,?,?,?)""",
            (user_id, norm, destination.strip(), available_seats, status, now),
        )
        return int(cur.lastrowid)


def list_open_drivers_for_destination(destination: str) -> list[dict]:
    """Passenger: drivers heading to the same normalized destination."""
    norm = normalize_destination(destination)
    with get_connection() as conn:
        rows = conn.execute(
            """
            SELECT o.id, o.destination_display, o.available_seats, o.created_at,
                   u.id AS driver_user_id, u.name AS driver_name, u.email AS driver_email
            FROM driver_offers o
            JOIN users u ON u.id = o.user_id
            WHERE o.destination_norm = ? AND o.status = 'open' AND o.available_seats > 0
            ORDER BY o.created_at DESC
            """,
            (norm,),
        ).fetchall()
    return [dict(r) for r in rows]


def list_open_passenger_requests_for_destination(destination: str) -> list[dict]:
    """Driver: passengers wanting a ride to the same destination."""
    norm = normalize_destination(destination)
    with get_connection() as conn:
        rows = conn.execute(
            """
            SELECT r.id, r.destination_display, r.passenger_count, r.created_at,
                   u.id AS passenger_user_id, u.name AS passenger_name, u.email AS passenger_email
            FROM passenger_requests r
            JOIN users u ON u.id = r.user_id
            WHERE r.destination_norm = ? AND r.status = 'open'
            ORDER BY r.created_at DESC
            """,
            (norm,),
        ).fetchall()
    return [dict(r) for r in rows]
