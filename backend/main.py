"""
Ride4Free local API — pairs with SQLite in database.py.
Run locally: uvicorn main:app --reload --host 127.0.0.1 --port 8000

Public URL for phones: ./start.sh (updates app_test/lib/app_config.dart)
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


def resolve_user_id(token: str | None) -> int | None:
    return db.user_id_from_token(token)


def require_user(authorization: str | None = Header(None)) -> int:
    token = bearer_token(authorization)
    uid = resolve_user_id(token)
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
    vehicle_info: str | None = None

class BookDriverOfferBody(BaseModel):
    offer_id: int = Field(ge=1)


class BookPassengerRequestBody(BaseModel):
    request_id: int = Field(ge=1)


class JoinRideBody(BaseModel):
    offer_id: int = Field(ge=1)
    passenger_count: int = Field(default=1, ge=1, le=20)


class RespondJoinBody(BaseModel):
    accept: bool


class RideMessageBody(BaseModel):
    body: str = Field(min_length=1, max_length=2000)


class RatingBody(BaseModel):
    stars: int = Field(ge=1, le=5)


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
    drivers = db.list_open_drivers_for_destination(destination, lat, lng, radius_m)
    for d in drivers:
        d.update(db._rating_fields(int(d["driver_user_id"])))
    return {
        "destination": destination.strip(),
        "drivers": drivers,
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
        vehicle_info=body.vehicle_info,
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
                **db._rating_fields(int(r["driver_user_id"])),
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

@app.post("/rides/join-requests")
def create_join_request(body: JoinRideBody, user_id: int = Depends(require_user)):
    try:
        rid = db.create_join_request(body.offer_id, user_id, body.passenger_count)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return {"id": rid, "message": "Join request sent"}


@app.get("/driver/offers/{offer_id}/join-requests")
def list_offer_join_requests(offer_id: int, user_id: int = Depends(require_user)):
    try:
        rows = db.list_join_requests_for_offer(offer_id, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return {"offer_id": offer_id, "requests": rows}


@app.get("/driver/my-offers/pending-requests")
def list_my_pending_requests(user_id: int = Depends(require_user)):
    offers = db.list_my_driver_offers_with_pending(user_id)
    return {"offers": offers}


@app.post("/rides/join-requests/{request_id}/respond")
def respond_join_request(request_id: int, body: RespondJoinBody, user_id: int = Depends(require_user)):
    try:
        result = db.respond_join_request(request_id, user_id, body.accept)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return result


@app.get("/rides/active")
def get_active_ride(user_id: int = Depends(require_user)):
    ride = db.get_active_ride_for_user(user_id)
    pending_rating = db.get_completed_ride_needing_rating(user_id)
    return {"ride": ride, "pending_rating": pending_rating}


@app.post("/rides/active/{ride_id}/in-car")
def confirm_in_car(ride_id: int, user_id: int = Depends(require_user)):
    try:
        ride = db.confirm_in_car(ride_id, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    if not ride:
        ride = db.get_active_ride_for_user(user_id)
    return {"ride": ride}


@app.post("/rides/active/{ride_id}/complete")
def complete_ride_endpoint(ride_id: int, user_id: int = Depends(require_user)):
    try:
        result = db.complete_ride(ride_id, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return result


@app.get("/rides/active/{ride_id}/messages")
def get_ride_messages(ride_id: int, user_id: int = Depends(require_user)):
    try:
        messages = db.list_ride_messages(ride_id, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return {"messages": messages}


@app.post("/rides/active/{ride_id}/messages")
def post_ride_message(ride_id: int, body: RideMessageBody, user_id: int = Depends(require_user)):
    try:
        msg = db.add_ride_message(ride_id, user_id, body.body)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return msg


@app.post("/rides/active/{ride_id}/rate")
def rate_ride_participant(ride_id: int, body: RatingBody, user_id: int = Depends(require_user)):
    try:
        result = db.submit_rating(ride_id, user_id, body.stars)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=409, detail="You already rated this ride")
    return result
