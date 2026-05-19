"""
Verify Firebase ID tokens (when FIREBASE_ENABLED=1).
"""

from __future__ import annotations

import os

import database as db

_firebase_ready = False


def firebase_enabled() -> bool:
    return os.environ.get("FIREBASE_ENABLED", "").strip().lower() in (
        "1",
        "true",
        "yes",
    )


def init_firebase() -> None:
    global _firebase_ready
    if not firebase_enabled() or _firebase_ready:
        return
    import firebase_admin
    from firebase_admin import credentials

    if firebase_admin._apps:
        _firebase_ready = True
        return

    cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "").strip()
    if cred_path:
        firebase_admin.initialize_app(credentials.Certificate(cred_path))
    else:
        firebase_admin.initialize_app()
    _firebase_ready = True


def user_id_from_firebase_token(token: str) -> int | None:
    from firebase_admin import auth

    init_firebase()
    decoded = auth.verify_id_token(token)
    uid = decoded.get("uid")
    if not uid:
        return None
    email = (decoded.get("email") or "").strip().lower()
    name = (decoded.get("name") or "").strip()
    if not name and email:
        name = email.split("@", 1)[0]
    if not name:
        name = "User"
    if not email:
        email = f"{uid}@firebase.local"
    return db.get_or_create_user_by_firebase_uid(str(uid), email, name)
