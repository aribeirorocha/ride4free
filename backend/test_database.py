"""
Unit tests for database.py — user management, sessions, requests, offers, bookings.
"""

import os
import tempfile
import pytest # type: ignore
import sqlite3
from pathlib import Path

# Setup temp DB for testing
@pytest.fixture(autouse=True)
def temp_db():
    """Provide a temporary database for each test."""
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    os.environ["RIDE4FREE_DB_PATH"] = path
    
    # Import after setting env var
    import database as db
    from importlib import reload
    reload(db)
    
    yield db, path
    
    # Cleanup
    if os.path.exists(path):
        os.unlink(path)
    if "RIDE4FREE_DB_PATH" in os.environ:
        del os.environ["RIDE4FREE_DB_PATH"]


class TestPasswordHashingAndVerification:
    """Tests for password hashing and verification functions."""
    
    def test_hash_password_creates_salted_hash(self, temp_db):
        db, _ = temp_db
        pwd = "test_password_123"
        hashed = db.hash_password(pwd)
        
        # Hash should contain salt and digest separated by $
        assert "$" in hashed
        parts = hashed.split("$")
        assert len(parts) == 2
        assert len(parts[0]) == 32  # hex(16 bytes) = 32 chars
        assert len(parts[1]) == 64  # hex(sha256) = 64 chars
    
    def test_hash_password_creates_different_hashes(self, temp_db):
        db, _ = temp_db
        pwd = "same_password"
        hash1 = db.hash_password(pwd)
        hash2 = db.hash_password(pwd)
        
        # Different salts should produce different hashes
        assert hash1 != hash2
    
    def test_verify_password_correct(self, temp_db):
        db, _ = temp_db
        pwd = "test_password_123"
        hashed = db.hash_password(pwd)
        
        assert db.verify_password(pwd, hashed) is True
    
    def test_verify_password_incorrect(self, temp_db):
        db, _ = temp_db
        pwd = "test_password_123"
        hashed = db.hash_password(pwd)
        
        assert db.verify_password("wrong_password", hashed) is False
    
    def test_verify_password_malformed_hash(self, temp_db):
        db, _ = temp_db
        assert db.verify_password("any", "malformed") is False
        assert db.verify_password("any", "") is False


class TestDestinationNormalization:
    """Tests for destination normalization."""
    
    def test_normalize_destination_lowercase(self, temp_db):
        db, _ = temp_db
        assert db.normalize_destination("FEUP") == "feup"
        assert db.normalize_destination("Estacao de Campanha") == "estacao de campanha"
    
    def test_normalize_destination_extra_spaces(self, temp_db):
        db, _ = temp_db
        assert db.normalize_destination("  FEUP  ") == "feup"
        assert db.normalize_destination("Estacao  de  Campanha") == "estacao de campanha"
    
    def test_normalize_destination_consistency(self, temp_db):
        db, _ = temp_db
        dest1 = db.normalize_destination("FEUP (Pole II)")
        dest2 = db.normalize_destination("feup (pole ii)")
        assert dest1 == dest2


class TestUserManagement:
    """Tests for user registration, retrieval, and authentication."""
    
    def test_insert_user_creates_user(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("alice@example.com", "password123", "Alice")
        
        assert uid > 0
        user = db.get_user_by_id(uid)
        assert user is not None
        assert user["email"] == "alice@example.com"
        assert user["name"] == "Alice"
    
    def test_insert_user_email_normalized(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("Alice@Example.COM", "password123", "Alice")
        user = db.get_user_by_email("alice@example.com")
        
        assert user is not None
        assert user["id"] == uid
    
    def test_insert_user_duplicate_email_raises_error(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        db.insert_user("alice@example.com", "password123", "Alice")
        
        with pytest.raises(sqlite3.IntegrityError):
            db.insert_user("alice@example.com", "other_password", "Alice Duplicate")
    
    def test_get_user_by_email_case_insensitive(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("alice@example.com", "password123", "Alice")
        user = db.get_user_by_email("ALICE@EXAMPLE.COM")
        
        assert user is not None
        assert user["id"] == uid
    
    def test_get_user_by_id_nonexistent(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        user = db.get_user_by_id(99999)
        assert user is None


class TestSessionManagement:
    """Tests for session tokens and authentication."""
    
    def test_create_session_returns_token(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("alice@example.com", "password123", "Alice")
        token = db.create_session(uid)
        
        assert token is not None
        assert len(token) > 0
    
    def test_create_session_tokens_are_unique(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("alice@example.com", "password123", "Alice")
        token1 = db.create_session(uid)
        token2 = db.create_session(uid)
        
        assert token1 != token2
    
    def test_user_id_from_token_valid(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("alice@example.com", "password123", "Alice")
        token = db.create_session(uid)
        
        retrieved_uid = db.user_id_from_token(token)
        assert retrieved_uid == uid
    
    def test_user_id_from_token_invalid(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        result = db.user_id_from_token("invalid_token_12345")
        assert result is None
    
    def test_user_id_from_token_none(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        result = db.user_id_from_token(None)
        assert result is None
    
    def test_delete_session(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("alice@example.com", "password123", "Alice")
        token = db.create_session(uid)
        
        db.delete_session(token)
        
        result = db.user_id_from_token(token)
        assert result is None


class TestPassengerRequests:
    """Tests for passenger request creation and listing."""
    
    def test_insert_passenger_request(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("alice@example.com", "password123", "Alice")
        rid = db.insert_passenger_request(uid, "FEUP", 2)
        
        assert rid > 0
    
    def test_list_open_passenger_requests(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("alice@example.com", "password123", "Alice")
        db.insert_passenger_request(uid, "FEUP", 1)
        db.insert_passenger_request(uid, "FEUP", 2)
        
        reqs = db.list_open_passenger_requests("FEUP")
        
        assert len(reqs) == 2
        assert reqs[0]["passenger_count"] in [1, 2]
    
    def test_list_passenger_requests_by_destination(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("alice@example.com", "password123", "Alice")
        db.insert_passenger_request(uid, "FEUP", 1)
        db.insert_passenger_request(uid, "City Center", 2)
        
        feup_reqs = db.list_open_passenger_requests("FEUP")
        city_reqs = db.list_open_passenger_requests("City Center")
        
        assert len(feup_reqs) == 1
        assert len(city_reqs) == 1
    
    def test_list_passenger_requests_empty(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        reqs = db.list_open_passenger_requests("FEUP")
        assert len(reqs) == 0


class TestDriverOffers:
    """Tests for driver offer creation and listing."""
    
    def test_insert_driver_offer(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("bob@example.com", "password123", "Bob")
        oid = db.insert_driver_offer(uid, "FEUP", 3)
        
        assert oid > 0
    
    def test_insert_driver_offer_status_open_when_seats_available(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("bob@example.com", "password123", "Bob")
        db.insert_driver_offer(uid, "FEUP", 3)
        
        offers = db.list_open_drivers("FEUP")
        assert len(offers) == 1
        assert offers[0]["available_seats"] == 3
    
    def test_insert_driver_offer_status_full_when_no_seats(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("bob@example.com", "password123", "Bob")
        db.insert_driver_offer(uid, "FEUP", 0)
        
        # full offers should not appear in open list
        offers = db.list_open_drivers("FEUP")
        assert len(offers) == 0
    
    def test_list_open_drivers_by_destination(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        uid = db.insert_user("bob@example.com", "password123", "Bob")
        db.insert_driver_offer(uid, "FEUP", 3)
        db.insert_driver_offer(uid, "City Center", 2)
        
        feup_offers = db.list_open_drivers("FEUP")
        city_offers = db.list_open_drivers("City Center")
        
        assert len(feup_offers) == 1
        assert len(city_offers) == 1


class TestRideBookings:
    """Tests for ride bookings (drivers and passengers)."""
    
    def test_book_driver_offer_success(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        driver = db.insert_user("driver@example.com", "password123", "Driver")
        passenger = db.insert_user("passenger@example.com", "password123", "Passenger")
        
        offer_id = db.insert_driver_offer(driver, "FEUP", 3)
        
        result = db.book_driver_offer(offer_id, passenger)
        
        assert "booking_id" in result
        assert result["offer_id"] == offer_id
    
    def test_book_driver_offer_nonexistent(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        passenger = db.insert_user("passenger@example.com", "password123", "Passenger")
        
        with pytest.raises(ValueError, match="Driver offer not found"):
            db.book_driver_offer(99999, passenger)
    
    def test_book_driver_offer_own_ride(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        driver = db.insert_user("driver@example.com", "password123", "Driver")
        offer_id = db.insert_driver_offer(driver, "FEUP", 3)
        
        with pytest.raises(ValueError, match="You cannot book your own ride"):
            db.book_driver_offer(offer_id, driver)
    
    def test_book_driver_offer_already_booked(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        driver = db.insert_user("driver@example.com", "password123", "Driver")
        passenger1 = db.insert_user("passenger1@example.com", "password123", "Passenger1")
        passenger2 = db.insert_user("passenger2@example.com", "password123", "Passenger2")
        
        offer_id = db.insert_driver_offer(driver, "FEUP", 1)
        db.book_driver_offer(offer_id, passenger1)
        
        with pytest.raises(ValueError, match="Driver offer already booked"):
            db.book_driver_offer(offer_id, passenger2)
    
    def test_book_passenger_request_success(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        passenger = db.insert_user("passenger@example.com", "password123", "Passenger")
        driver = db.insert_user("driver@example.com", "password123", "Driver")
        
        request_id = db.insert_passenger_request(passenger, "FEUP", 2)
        
        result = db.book_passenger_request(request_id, driver)
        
        assert "booking_id" in result
        assert result["request_id"] == request_id
    
    def test_book_passenger_request_own_request(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        passenger = db.insert_user("passenger@example.com", "password123", "Passenger")
        request_id = db.insert_passenger_request(passenger, "FEUP", 2)
        
        with pytest.raises(ValueError, match="You cannot book your own passenger request"):
            db.book_passenger_request(request_id, passenger)
    
    def test_book_passenger_request_nonexistent(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        driver = db.insert_user("driver@example.com", "password123", "Driver")
        
        with pytest.raises(ValueError, match="Passenger request not found"):
            db.book_passenger_request(99999, driver)

    def test_book_passenger_request_already_booked(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        passenger = db.insert_user("passenger@example.com", "password123", "Passenger")
        driver1 = db.insert_user("driver1@example.com", "password123", "Driver1")
        driver2 = db.insert_user("driver2@example.com", "password123", "Driver2")
        
        request_id = db.insert_passenger_request(passenger, "FEUP", 2)
        db.book_passenger_request(request_id, driver1)
        
        with pytest.raises(ValueError, match="Passenger request already booked"):
            db.book_passenger_request(request_id, driver2)


class TestCommunityListing:
    """Tests for community board listing functions."""
    
    def test_list_community_drivers(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        driver = db.insert_user("driver@example.com", "password123", "Driver")
        db.insert_driver_offer(driver, "FEUP", 3)
        
        drivers = db.list_community_drivers()
        
        assert len(drivers) >= 1
        assert drivers[0]["driver_name"] == "Driver"
        assert drivers[0]["available_seats"] == 3
    
    def test_list_community_drivers_with_booking_info(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        driver = db.insert_user("driver@example.com", "password123", "Driver")
        passenger = db.insert_user("passenger@example.com", "password123", "Passenger")
        
        offer_id = db.insert_driver_offer(driver, "FEUP", 1)
        db.book_driver_offer(offer_id, passenger)
        
        drivers = db.list_community_drivers()
        
        assert len(drivers) >= 1
        assert drivers[0]["booking_id"] is not None
        assert drivers[0]["booked_by_name"] == "Passenger"
    
    def test_list_community_passengers(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        passenger = db.insert_user("passenger@example.com", "password123", "Passenger")
        db.insert_passenger_request(passenger, "FEUP", 2)
        
        passengers = db.list_community_passengers()
        
        assert len(passengers) >= 1
        assert passengers[0]["passenger_name"] == "Passenger"
        assert passengers[0]["passenger_count"] == 2
    
    def test_list_community_drivers_by_destination(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        driver = db.insert_user("driver@example.com", "password123", "Driver")
        db.insert_driver_offer(driver, "FEUP", 3)
        db.insert_driver_offer(driver, "City Center", 2)
        
        feup = db.list_community_drivers("FEUP")
        city = db.list_community_drivers("City Center")
        
        assert len(feup) == 1
        assert len(city) == 1


class TestDatabaseSchema:
    """Tests for database schema exposure."""
    
    def test_get_database_schema(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        schema = db.get_database_schema()
        
        assert "tables" in schema
        tables = schema["tables"]
        
        # Verify expected tables exist
        assert "users" in tables
        assert "sessions" in tables
        assert "passenger_requests" in tables
        assert "driver_offers" in tables
        assert "ride_bookings" in tables
    
    def test_get_database_schema_has_column_info(self, temp_db):
        db, _ = temp_db
        db.init_db()
        
        schema = db.get_database_schema()
        users_cols = schema["tables"]["users"]
        
        # Check that columns have expected fields
        assert len(users_cols) > 0
        col = users_cols[0]
        
        assert "name" in col
        assert "type" in col
        assert "not_null" in col
        assert "primary_key" in col



@pytest.fixture(autouse=True)
def temp_db():
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    os.environ["RIDE4FREE_DB_PATH"] = path

    import database as db
    from importlib import reload
    reload(db)

    yield db, path

    if os.path.exists(path):
        os.unlink(path)
    if "RIDE4FREE_DB_PATH" in os.environ:
        del os.environ["RIDE4FREE_DB_PATH"]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

@pytest.fixture
def make_user(temp_db):
    """Devolve uma função que cria utilizadores na DB de teste."""
    db, _ = temp_db
    db.init_db()
    _counter = [0]

    def _make(email=None, name=None):
        _counter[0] += 1
        e = email or f"user{_counter[0]}@example.com"
        n = name or f"User{_counter[0]}"
        return db.insert_user(e, "password123", n)

    return _make


# Coordenadas reais: FEUP e Residência Universitária do Porto
FEUP_LAT, FEUP_LNG = 41.1780, -8.5980
RESIDENCIA_LAT, RESIDENCIA_LNG = 41.1850, -8.6020  # ~850 m de FEUP
FAR_LAT, FAR_LNG = 41.3000, -8.7500                # ~18 km de FEUP


# ---------------------------------------------------------------------------
# 1. departure_time e description
# ---------------------------------------------------------------------------

class TestDriverOfferNewFields:

    def test_insert_driver_offer_with_departure_time(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        oid = db.insert_driver_offer(uid, "FEUP", 3, departure_time="08:15")
        assert oid > 0

    def test_insert_driver_offer_with_description(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        oid = db.insert_driver_offer(uid, "FEUP", 3, description="Passo pela rotunda")
        assert oid > 0

    def test_insert_driver_offer_with_both_new_fields(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        oid = db.insert_driver_offer(uid, "FEUP", 2, departure_time="09:00", description="Saio pontual")
        assert oid > 0

    def test_departure_time_persisted_in_community_drivers(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(uid, "FEUP", 2, departure_time="07:45")

        drivers = db.list_community_drivers()
        assert drivers[0]["departure_time"] == "07:45"

    def test_description_persisted_in_community_drivers(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(uid, "FEUP", 2, description="Tenho mala grande")

        drivers = db.list_community_drivers()
        assert drivers[0]["description"] == "Tenho mala grande"

    def test_departure_time_none_by_default(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(uid, "FEUP", 2)

        drivers = db.list_community_drivers()
        assert drivers[0]["departure_time"] is None

    def test_description_none_by_default(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(uid, "FEUP", 2)

        drivers = db.list_community_drivers()
        assert drivers[0]["description"] is None

    def test_departure_time_visible_in_list_open_drivers(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(uid, "FEUP", 2, departure_time="08:15")

        offers = db.list_open_drivers("FEUP")
        assert offers[0]["departure_time"] == "08:15"

    def test_description_visible_in_list_open_drivers(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(uid, "FEUP", 2, description="Só mulheres")

        offers = db.list_open_drivers("FEUP")
        assert offers[0]["description"] == "Só mulheres"


# ---------------------------------------------------------------------------
# 2. Coordenadas GPS
# ---------------------------------------------------------------------------

class TestGPSCoordinates:

    def test_insert_driver_offer_with_origin_coords(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        oid = db.insert_driver_offer(
            uid, "FEUP", 3,
            origin_lat=RESIDENCIA_LAT, origin_lng=RESIDENCIA_LNG
        )
        assert oid > 0

    def test_insert_driver_offer_with_destination_coords(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        oid = db.insert_driver_offer(
            uid, "FEUP", 3,
            destination_lat=FEUP_LAT, destination_lng=FEUP_LNG
        )
        assert oid > 0

    def test_origin_coords_persisted_in_community_drivers(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(
            uid, "FEUP", 2,
            origin_lat=RESIDENCIA_LAT, origin_lng=RESIDENCIA_LNG
        )
        drivers = db.list_community_drivers()
        assert drivers[0]["origin_lat"] == pytest.approx(RESIDENCIA_LAT, abs=1e-6)
        assert drivers[0]["origin_lng"] == pytest.approx(RESIDENCIA_LNG, abs=1e-6)

    def test_passenger_request_with_origin_coords(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        rid = db.insert_passenger_request(
            uid, "FEUP", 1,
            origin_lat=RESIDENCIA_LAT, origin_lng=RESIDENCIA_LNG
        )
        assert rid > 0


# ---------------------------------------------------------------------------
# 3. Haversine e filtro por raio
# ---------------------------------------------------------------------------

class TestHaversineAndRadiusFilter:

    def test_haversine_same_point_is_zero(self, temp_db, make_user):
        db, _ = temp_db
        dist = db.haversine_meters(FEUP_LAT, FEUP_LNG, FEUP_LAT, FEUP_LNG)
        assert dist == pytest.approx(0.0, abs=1e-3)

    def test_haversine_known_distance(self, temp_db, make_user):
        db, _ = temp_db
        # FEUP <-> Residência ~850 m
        dist = db.haversine_meters(FEUP_LAT, FEUP_LNG, RESIDENCIA_LAT, RESIDENCIA_LNG)
        assert 700 < dist < 1000

    def test_haversine_far_distance(self, temp_db, make_user):
        db, _ = temp_db
        dist = db.haversine_meters(FEUP_LAT, FEUP_LNG, FAR_LAT, FAR_LNG)
        assert dist > 10_000

    def test_list_open_drivers_radius_includes_nearby(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        # Oferta com destino em FEUP
        db.insert_driver_offer(
            uid, "FEUP", 2,
            destination_lat=FEUP_LAT, destination_lng=FEUP_LNG
        )
        # Passageiro em Residência (< 1000 m de FEUP), raio 1500 m
        offers = db.list_open_drivers(
            passenger_lat=RESIDENCIA_LAT,
            passenger_lng=RESIDENCIA_LNG,
            radius_m=1500
        )
        assert len(offers) == 1

    def test_list_open_drivers_radius_excludes_far(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        # Oferta com destino em FEUP
        db.insert_driver_offer(
            uid, "FEUP", 2,
            destination_lat=FEUP_LAT, destination_lng=FEUP_LNG
        )
        # Passageiro muito longe, raio 500 m
        offers = db.list_open_drivers(
            passenger_lat=FAR_LAT,
            passenger_lng=FAR_LNG,
            radius_m=500
        )
        assert len(offers) == 0

    def test_list_community_drivers_radius_includes_nearby(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(
            uid, "FEUP", 2,
            origin_lat=RESIDENCIA_LAT, origin_lng=RESIDENCIA_LNG
        )
        drivers = db.list_community_drivers(
            passenger_lat=RESIDENCIA_LAT,
            passenger_lng=RESIDENCIA_LNG,
            radius_m=100
        )
        assert len(drivers) == 1

    def test_list_community_drivers_radius_excludes_far(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(
            uid, "FEUP", 2,
            origin_lat=RESIDENCIA_LAT, origin_lng=RESIDENCIA_LNG
        )
        drivers = db.list_community_drivers(
            passenger_lat=FAR_LAT,
            passenger_lng=FAR_LNG,
            radius_m=500
        )
        assert len(drivers) == 0

    def test_radius_filter_no_coords_returns_all(self, temp_db, make_user):
        """Sem coordenadas de passageiro, não filtra por raio."""
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(uid, "FEUP", 2)
        db.insert_driver_offer(uid, "City Center", 3)

        drivers = db.list_community_drivers()
        assert len(drivers) == 2

    def test_offer_without_coords_excluded_from_radius_filter(self, temp_db, make_user):
        """Oferta sem coordenadas é excluída quando se filtra por raio."""
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(uid, "FEUP", 2)  # sem coords

        offers = db.list_open_drivers(
            passenger_lat=RESIDENCIA_LAT,
            passenger_lng=RESIDENCIA_LNG,
            radius_m=5000
        )
        assert len(offers) == 0


# ---------------------------------------------------------------------------
# 4. list_open_drivers (a função de pesquisa do passageiro)
# ---------------------------------------------------------------------------

class TestListOpenDrivers:

    def test_list_open_drivers_returns_open_only(self, temp_db, make_user):
        db, _ = temp_db
        driver = make_user("driver@example.com", "Driver")
        passenger = make_user("p@example.com", "P")
        offer_id = db.insert_driver_offer(driver, "FEUP", 1)
        db.book_driver_offer(offer_id, passenger)  # fica 'full'

        offers = db.list_open_drivers("FEUP")
        assert len(offers) == 0

    def test_list_open_drivers_returns_multiple(self, temp_db, make_user):
        db, _ = temp_db
        d1 = make_user("d1@example.com", "D1")
        d2 = make_user("d2@example.com", "D2")
        db.insert_driver_offer(d1, "FEUP", 2)
        db.insert_driver_offer(d2, "FEUP", 3)

        offers = db.list_open_drivers("FEUP")
        assert len(offers) == 2

    def test_list_open_drivers_ignores_other_destinations(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(uid, "FEUP", 2)
        db.insert_driver_offer(uid, "City Center", 2)

        offers = db.list_open_drivers("FEUP")
        assert len(offers) == 1
        assert offers[0]["destination_display"] == "FEUP"

    def test_list_open_drivers_has_driver_info(self, temp_db, make_user):
        db, _ = temp_db
        uid = make_user("driver@example.com", "Bob")
        db.insert_driver_offer(uid, "FEUP", 2)

        offers = db.list_open_drivers("FEUP")
        assert offers[0]["driver_name"] == "Bob"
        assert offers[0]["driver_user_id"] == uid

    def test_list_open_drivers_for_destination_alias(self, temp_db, make_user):
        """list_open_drivers_for_destination é alias de list_open_drivers."""
        db, _ = temp_db
        uid = make_user()
        db.insert_driver_offer(uid, "FEUP", 2)

        offers = db.list_open_drivers_for_destination("FEUP")
        assert len(offers) == 1


# ---------------------------------------------------------------------------
# 5. list_community_passengers com estado fulfilled
# ---------------------------------------------------------------------------

class TestCommunityPassengersStates:

    def test_fulfilled_passenger_still_appears_in_community(self, temp_db, make_user):
        db, _ = temp_db
        passenger = make_user("p@example.com", "Passenger")
        driver = make_user("d@example.com", "Driver")

        request_id = db.insert_passenger_request(passenger, "FEUP", 1)
        db.book_passenger_request(request_id, driver)

        passengers = db.list_community_passengers()
        assert len(passengers) == 1
        assert passengers[0]["status"] == "fulfilled"

    def test_cancelled_passenger_not_in_community(self, temp_db, make_user):
        """Pedidos cancelados não aparecem na community board."""
        db, _ = temp_db
        uid = make_user()

        rid = db.insert_passenger_request(uid, "FEUP", 1)

        # Cancela manualmente via SQL
        import sqlite3
        path = os.environ["RIDE4FREE_DB_PATH"]
        conn = sqlite3.connect(path)
        conn.execute("UPDATE passenger_requests SET status = 'cancelled' WHERE id = ?", (rid,))
        conn.commit()
        conn.close()

        passengers = db.list_community_passengers()
        assert len(passengers) == 0

    def test_fulfilled_passenger_has_booking_info(self, temp_db, make_user):
        db, _ = temp_db
        passenger = make_user("p@example.com", "Passenger")
        driver = make_user("d@example.com", "Driver")

        request_id = db.insert_passenger_request(passenger, "FEUP", 1)
        db.book_passenger_request(request_id, driver)

        passengers = db.list_community_passengers()
        assert passengers[0]["booking_id"] is not None
        assert passengers[0]["booked_by_name"] == "Driver"

    def test_open_and_fulfilled_both_visible(self, temp_db, make_user):
        db, _ = temp_db
        passenger = make_user("p@example.com", "Passenger")
        driver = make_user("d@example.com", "Driver")

        db.insert_passenger_request(passenger, "FEUP", 1)           # open
        rid2 = db.insert_passenger_request(passenger, "City Center", 1)
        db.book_passenger_request(rid2, driver)                      # fulfilled

        passengers = db.list_community_passengers()
        statuses = {r["status"] for r in passengers}
        assert "open" in statuses
        assert "fulfilled" in statuses