"""
Ride4Free local API — pairs with SQLite in database.py.
Run: uvicorn main:app --reload --host 0.0.0.0 --port 8000

Later: deploy API (Cloud Run / Cloud Functions) and point the Flutter app at
that base URL; replace database.py calls with Firebase Admin or Firestore SDK.
"""

from __future__ import annotations

import sqlite3

from contextlib import asynccontextmanager
from fastapi import Depends, FastAPI, HTTPException, Header, Query, status # type: ignore
from fastapi.middleware.cors import CORSMiddleware # type: ignore
from pydantic import BaseModel, EmailStr, Field # type: ignore

import database as db


@asynccontextmanager
async def lifespan(app: FastAPI):
    db.init_db()
    yield

app = FastAPI(title="Ride4Free API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Auth dependency ---


def bearer_token(authorization: str | None = None) -> str | None:
    if not authorization:
        return None
    prefix = "Bearer "
    if authorization.startswith(prefix):
        return authorization[len(prefix) :].strip()
    return None


def require_user(authorization: str | None = Header(None)) -> int:
    token = bearer_token(authorization)
    uid = db.user_id_from_token(token)
    if uid is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or missing session")
    return uid


# --- Schemas ---


class RegisterBody(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    name: str = Field(min_length=1, max_length=200)


class LoginBody(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: int
    email: str
    name: str


class TokenResponse(BaseModel):
    token: str
    user: UserOut


class PassengerRequestBody(BaseModel):
    destination: str = Field(min_length=1, max_length=500)
    passenger_count: int = Field(default=1, ge=1, le=20)
    origin_lat: float | None = None
    origin_lng: float | None = None

class DriverOfferBody(BaseModel):
    destination: str = Field(min_length=1, max_length=500)
    available_seats: int = Field(ge=0, le=20)
    departure_time: str | None = None 
    description: str | None = None
    origin_lat: float | None = None
    origin_lng: float | None = None
    destination_lat: float | None = None
    destination_lng: float | None = None

class BookDriverOfferBody(BaseModel):
    offer_id: int = Field(ge=1)


class BookPassengerRequestBody(BaseModel):
    request_id: int = Field(ge=1)


# --- Routes ---


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/users/register", response_model=TokenResponse)
def register(body: RegisterBody):
    try:
        uid = db.insert_user(body.email, body.password, body.name)
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=409, detail="Email already registered")
    token = db.create_session(uid)
    row = db.get_user_by_id(uid)
    assert row is not None
    return TokenResponse(
        token=token,
        user=UserOut(id=row["id"], email=row["email"], name=row["name"]),
    )


@app.post("/users/login", response_model=TokenResponse)
def login(body: LoginBody):
    row = db.get_user_by_email(body.email)
    if row is None or not db.verify_password(body.password, row["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    token = db.create_session(int(row["id"]))
    return TokenResponse(
        token=token,
        user=UserOut(id=row["id"], email=row["email"], name=row["name"]),
    )


@app.post("/users/logout")
def logout(user_id: int = Depends(require_user), authorization: str | None = Header(None)):
    token = bearer_token(authorization)
    if token:
        db.delete_session(token)
    return {"ok": True}


@app.get("/users/me", response_model=UserOut)
def me(user_id: int = Depends(require_user)):
    row = db.get_user_by_id(user_id)
    if not row:
        raise HTTPException(status_code=404, detail="User not found")
    return UserOut(id=row["id"], email=row["email"], name=row["name"])


@app.post("/passenger/requests")
def create_passenger_request(body: PassengerRequestBody, user_id: int = Depends(require_user)):
    rid = db.insert_passenger_request(
        user_id,
        body.destination,
        body.passenger_count,
        origin_lat=body.origin_lat,
        origin_lng=body.origin_lng,
    )
    return {"id": rid, "message": "Request created"}


@app.get("/passenger/drivers")
def list_drivers_for_passenger(
        destination: str,
        lat: float | None = None,
        lng: float | None = None,
        radius_m: int = Query(default=500, ge=100, le=2000),
        user_id: int = Depends(require_user),
):
    if not destination.strip():
        raise HTTPException(status_code=400, detail="destination is required")
    return {
        "destination": destination.strip(),
        "drivers": db.list_open_drivers_for_destination(destination, lat, lng, radius_m),
    }


@app.post("/driver/offers")
def create_driver_offer(body: DriverOfferBody, user_id: int = Depends(require_user)):
    oid = db.insert_driver_offer(
        user_id,
        body.destination,
        body.available_seats,
        departure_time=body.departure_time, 
        description=body.description,      
        origin_lat=body.origin_lat,
        origin_lng=body.origin_lng,
        destination_lat=body.destination_lat,
        destination_lng=body.destination_lng,
    )
    return {"id": oid, "message": "Offer created"}


@app.get("/driver/passengers")
def list_passengers_for_driver(destination: str, user_id: int = Depends(require_user)):
    if not destination.strip():
        raise HTTPException(status_code=400, detail="destination is required")
    rows = db.list_open_passenger_requests_for_destination(destination)
    total_passengers = sum(r["passenger_count"] for r in rows)
    return {
        "destination": destination.strip(),
        "total_passengers": total_passengers,
        "rows": rows,
    }


@app.get("/community/drivers")
def list_available_drivers(
        destination: str | None = None,
        lat: float | None = None,
        lng: float | None = None,
        radius_m: int = Query(default=500, ge=100, le=2000),
        user_id: int = Depends(require_user),
):
    rows = db.list_community_drivers(destination, lat, lng, radius_m)
    return {
        "destination_filter": destination.strip() if destination else None,
        "drivers": [
            {
                **r,
                "booked": bool(r.get("booking_id")),
                "profile_description": (
                    f"{r['driver_name']} is heading to {r['destination_display']} "
                    f"with {r['available_seats']} seat(s) available."
                    if not r.get("booking_id")
                    else f"{r['driver_name']}'s ride to {r['destination_display']} "
                         f"was booked by {r.get('booked_by_name', 'another user')}."
                ),
            }
            for r in rows
        ],
    }


@app.get("/community/passengers")
def list_available_passengers(destination: str | None = None, user_id: int = Depends(require_user)):
    rows = db.list_community_passengers(destination)
    return {
        "destination_filter": destination.strip() if destination else None,
        "passengers": [
            {
                **r,
                "booked": bool(r.get("booking_id")),
                "profile_description": (
                    f"{r['passenger_name']} needs {r['passenger_count']} seat(s) "
                    f"to {r['destination_display']}."
                    if not r.get("booking_id")
                    else f"{r['passenger_name']}'s request to {r['destination_display']} "
                         f"was booked by {r.get('booked_by_name', 'another user')}."
                ),
            }
            for r in rows
        ],
    }


@app.get("/database/schema")
def get_database_schema(user_id: int = Depends(require_user)):
    return db.get_database_schema()


@app.post("/bookings/driver-offer")
def book_driver_offer(body: BookDriverOfferBody, user_id: int = Depends(require_user)):
    try:
        result = db.book_driver_offer(body.offer_id, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return {"message": "Driver offer booked", **result}


@app.post("/bookings/passenger-request")
def book_passenger_request(body: BookPassengerRequestBody, user_id: int = Depends(require_user)):
    try:
        result = db.book_passenger_request(body.request_id, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return {"message": "Passenger request booked", **result}