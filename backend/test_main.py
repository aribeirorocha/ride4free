"""
Integration tests for main.py — FastAPI endpoints for Ride4Free.
"""

import os
import tempfile
import pytest # type: ignore
from fastapi.testclient import TestClient # type: ignore

@pytest.fixture
def client():
    """Provide an isolated TestClient and temporary database for each test."""
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    os.environ["RIDE4FREE_DB_PATH"] = path

    import database as db
    import main
    from importlib import reload

    # Reload modules to ensure the temporary DB path is used by the app.
    db = reload(db)
    main = reload(main)
    main.db = db

    db.init_db()
    client = TestClient(main.app)

    try:
        yield client
    finally:
        client.close()
        if os.path.exists(path):
            os.unlink(path)
        if "RIDE4FREE_DB_PATH" in os.environ:
            del os.environ["RIDE4FREE_DB_PATH"]


@pytest.fixture
def auth_token(client):
    """Create a test user and return auth token."""
    response = client.post(
        "/users/register",
        json={"email": "user@test.com", "password": "password123", "name": "Test User"}
    )
    assert response.status_code == 200
    return response.json()["token"]


class TestHealthEndpoint:
    """Tests for the health check endpoint."""
    
    def test_health_check(self, client):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}


class TestUserRegistration:
    """Tests for user registration endpoint."""
    
    def test_register_success(self, client):
        response = client.post(
            "/users/register",
            json={"email": "alice@example.com", "password": "password123", "name": "Alice"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["token"] is not None
        assert data["user"]["email"] == "alice@example.com"
        assert data["user"]["name"] == "Alice"
        assert "id" in data["user"]
    
    def test_register_duplicate_email(self, client):
        client.post(
            "/users/register",
            json={"email": "alice@example.com", "password": "password123", "name": "Alice"}
        )
        
        response = client.post(
            "/users/register",
            json={"email": "alice@example.com", "password": "other123", "name": "Alice 2"}
        )
        
        assert response.status_code == 409
        assert "already registered" in response.json()["detail"]
    
    def test_register_invalid_email(self, client):
        response = client.post(
            "/users/register",
            json={"email": "not-an-email", "password": "password123", "name": "Alice"}
        )
        
        assert response.status_code == 422
    
    def test_register_password_too_short(self, client):
        response = client.post(
            "/users/register",
            json={"email": "alice@example.com", "password": "pass", "name": "Alice"}
        )
        
        assert response.status_code == 422
    
    def test_register_empty_name(self, client):
        response = client.post(
            "/users/register",
            json={"email": "alice@example.com", "password": "password123", "name": ""}
        )
        
        assert response.status_code == 422


class TestUserLogin:
    """Tests for user login endpoint."""
    
    @pytest.fixture
    def test_user(self, client):
        """Create a test user."""
        response = client.post(
            "/users/register",
            json={"email": "user@test.com", "password": "password123", "name": "Test User"}
        )
        assert response.status_code == 200
        return response.json()["user"]
    
    def test_login_success(self, client, test_user):
        response = client.post(
            "/users/login",
            json={"email": "user@test.com", "password": "password123"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["token"] is not None
        assert data["user"]["email"] == "user@test.com"
        assert data["user"]["id"] == test_user["id"]
    
    def test_login_wrong_password(self, client, test_user):
        response = client.post(
            "/users/login",
            json={"email": "user@test.com", "password": "wrongpassword"}
        )
        
        assert response.status_code == 401
        assert "Invalid email or password" in response.json()["detail"]
    
    def test_login_nonexistent_email(self, client, test_user):
        response = client.post(
            "/users/login",
            json={"email": "nonexistent@test.com", "password": "password123"}
        )
        
        assert response.status_code == 401
        assert "Invalid email or password" in response.json()["detail"]
    
    def test_login_case_insensitive_email(self, client, test_user):
        response = client.post(
            "/users/login",
            json={"email": "USER@TEST.COM", "password": "password123"}
        )
        
        assert response.status_code == 200


class TestUserProfile:
    """Tests for getting current user profile."""
    
    def test_get_profile_authenticated(self, client, auth_token):
        response = client.get(
            "/users/me",
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "user@test.com"
        assert data["name"] == "Test User"
    
    def test_get_profile_no_auth(self, client):
        response = client.get("/users/me")
        
        assert response.status_code == 401
        assert "Invalid or missing session" in response.json()["detail"]
    
    def test_get_profile_invalid_token(self, client):
        response = client.get(
            "/users/me",
            headers={"Authorization": "Bearer invalid_token_12345"}
        )
        
        assert response.status_code == 401


class TestLogout:
    """Tests for logout endpoint."""
    
    def test_logout_valid_token(self, client, auth_token):
        response = client.post(
            "/users/logout",
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        
        assert response.status_code == 200
        assert response.json()["ok"] is True
    
    def test_logout_no_token(self, client):
        response = client.post("/users/logout")
        
        assert response.status_code == 401
    
    def test_logout_token_invalidated(self, client, auth_token):
        # Logout
        response = client.post(
            "/users/logout",
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        assert response.status_code == 200
        
        # Try to use token after logout
        response = client.get(
            "/users/me",
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        
        assert response.status_code == 401


class TestPassengerRequests:
    """Tests for passenger request endpoints."""
    
    def test_create_passenger_request(self, client, auth_token):
        response = client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "passenger_count": 2}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] > 0
        assert "message" in data
    
    def test_create_passenger_request_no_auth(self, client):
        response = client.post(
            "/passenger/requests",
            json={"destination": "FEUP", "passenger_count": 2}
        )
        
        assert response.status_code == 401
    
    def test_create_passenger_request_invalid_count(self, client, auth_token):
        response = client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "passenger_count": 0}
        )
        
        assert response.status_code == 422
    
    def test_create_passenger_request_excess_count(self, client, auth_token):
        response = client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "passenger_count": 25}
        )
        
        assert response.status_code == 422
    
    def test_create_passenger_request_empty_destination(self, client, auth_token):
        response = client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "", "passenger_count": 1}
        )
        
        assert response.status_code == 422


class TestDriverOffers:
    """Tests for driver offer endpoints."""
    
    def test_create_driver_offer(self, client, auth_token):
        response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "available_seats": 3}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] > 0
    
    def test_create_driver_offer_zero_seats(self, client, auth_token):
        response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "available_seats": 0}
        )
        
        assert response.status_code == 200
    
    def test_create_driver_offer_no_auth(self, client):
        response = client.post(
            "/driver/offers",
            json={"destination": "FEUP", "available_seats": 3}
        )
        
        assert response.status_code == 401
    
    def test_list_drivers_for_passenger(self, client, auth_token):
        # Create a driver offer first
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "available_seats": 3}
        )
        
        # List drivers for passenger
        response = client.get(
            "/passenger/drivers",
            headers={"Authorization": f"Bearer {auth_token}"},
            params={"destination": "FEUP"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["destination"] == "FEUP"
        assert "drivers" in data
        assert len(data["drivers"]) >= 1
    
    def test_list_drivers_empty_destination(self, client, auth_token):
        # Destino com só espaços: endpoint devolve 200 com mensagem de aviso
        response = client.get(
            "/passenger/drivers",
            headers={"Authorization": f"Bearer {auth_token}"},
            params={"destination": "   "}
        )
        assert response.status_code == 200
        assert "message" in response.json()


class TestPassengerListing:
    """Tests for passenger request listing endpoints."""
    
    def test_list_passengers_for_driver(self, client, auth_token):
        # Create a passenger request first
        client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "passenger_count": 2}
        )
        
        # List passengers for driver
        response = client.get(
            "/driver/passengers",
            headers={"Authorization": f"Bearer {auth_token}"},
            params={"destination": "FEUP"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["destination"] == "FEUP"
        assert "rows" in data
        assert "total_passengers" in data


class TestCommunityBoard:
    """Tests for community board endpoints."""
    
    def test_list_community_drivers(self, client, auth_token):
        # Create driver offer
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "available_seats": 3}
        )
        
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "drivers" in data
        assert len(data["drivers"]) >= 1
        assert "profile_description" in data["drivers"][0]
    
    def test_list_community_drivers_filtered_by_destination(self, client, auth_token):
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "available_seats": 3}
        )
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "City Center", "available_seats": 2}
        )
        
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {auth_token}"},
            params={"destination": "FEUP"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert len(data["drivers"]) == 1
    
    def test_list_community_passengers(self, client, auth_token):
        client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "passenger_count": 2}
        )
        
        response = client.get(
            "/community/passengers",
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "passengers" in data
        assert len(data["passengers"]) >= 1


class TestBookings:
    """Tests for booking endpoints."""
    
    def test_book_driver_offer(self, client):
        # Create two users
        response1 = client.post(
            "/users/register",
            json={"email": "driver@test.com", "password": "password123", "name": "Driver"}
        )
        driver_token = response1.json()["token"]
        
        response2 = client.post(
            "/users/register",
            json={"email": "passenger@test.com", "password": "password123", "name": "Passenger"}
        )
        passenger_token = response2.json()["token"]
        
        # Driver creates offer
        offer_response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 3}
        )
        offer_id = offer_response.json()["id"]
        
        # Passenger books
        response = client.post(
            "/bookings/driver-offer",
            headers={"Authorization": f"Bearer {passenger_token}"},
            json={"offer_id": offer_id}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["booking_id"] > 0
    
    def test_book_driver_offer_own_ride(self, client, auth_token):
        # Create offer
        offer_response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "available_seats": 3}
        )
        offer_id = offer_response.json()["id"]
        
        # Try to book own offer
        response = client.post(
            "/bookings/driver-offer",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"offer_id": offer_id}
        )
        
        assert response.status_code == 400
        assert "own ride" in response.json()["detail"]
    
    def test_book_driver_offer_nonexistent(self, client, auth_token):
        response = client.post(
            "/bookings/driver-offer",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"offer_id": 99999}
        )
        
        assert response.status_code == 400
    
    def test_book_passenger_request(self, client):
        # Create two users
        response1 = client.post(
            "/users/register",
            json={"email": "passenger@test.com", "password": "password123", "name": "Passenger"}
        )
        passenger_token = response1.json()["token"]
        
        response2 = client.post(
            "/users/register",
            json={"email": "driver@test.com", "password": "password123", "name": "Driver"}
        )
        driver_token = response2.json()["token"]
        
        # Passenger creates request
        req_response = client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {passenger_token}"},
            json={"destination": "FEUP", "passenger_count": 2}
        )
        request_id = req_response.json()["id"]
        
        # Driver books
        response = client.post(
            "/bookings/passenger-request",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"request_id": request_id}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["booking_id"] > 0
    
    def test_book_passenger_request_own_request(self, client, auth_token):
        # Create request
        req_response = client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"destination": "FEUP", "passenger_count": 2}
        )
        request_id = req_response.json()["id"]
        
        # Try to book own request
        response = client.post(
            "/bookings/passenger-request",
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"request_id": request_id}
        )
        
        assert response.status_code == 400
        assert "own passenger request" in response.json()["detail"]


class TestDatabaseSchema:
    """Tests for database schema endpoint."""
    
    def test_get_database_schema(self, client, auth_token):
        response = client.get(
            "/database/schema",
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        
        assert "tables" in data
        tables = data["tables"]
        
        expected_tables = ["users", "sessions", "passenger_requests", "driver_offers", "ride_bookings"]
        for table in expected_tables:
            assert table in tables
    
    def test_get_database_schema_requires_auth(self, client):
        response = client.get("/database/schema")
        
        assert response.status_code == 401


@pytest.fixture
def two_tokens(client):
    """Cria dois utilizadores e devolve (driver_token, passenger_token)."""
    r1 = client.post("/users/register", json={
        "email": "driver@test.com", "password": "password123", "name": "Driver"
    })
    r2 = client.post("/users/register", json={
        "email": "passenger@test.com", "password": "password123", "name": "Passenger"
    })
    return r1.json()["token"], r2.json()["token"]


# Coordenadas: FEUP e Residência (< 1 km), ponto distante (> 15 km)
FEUP = {"lat": 41.1780, "lng": -8.5980}
RESIDENCIA = {"lat": 41.1850, "lng": -8.6020}
FAR = {"lat": 41.3000, "lng": -8.7500}


# ---------------------------------------------------------------------------
# 1. departure_time e description em /driver/offers
# ---------------------------------------------------------------------------

class TestDriverOfferNewFields:

    def test_create_offer_with_departure_time(self, client, two_tokens):
        driver_token, _ = two_tokens
        response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 2, "departure_time": "08:15"}
        )
        assert response.status_code == 200
        assert response.json()["id"] > 0

    def test_create_offer_with_description(self, client, two_tokens):
        driver_token, _ = two_tokens
        response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 2, "description": "Passo pela rotunda"}
        )
        assert response.status_code == 200
        assert response.json()["id"] > 0

    def test_create_offer_with_both_new_fields(self, client, two_tokens):
        driver_token, _ = two_tokens
        response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={
                "destination": "FEUP",
                "available_seats": 3,
                "departure_time": "09:00",
                "description": "Saio pontual, não espero"
            }
        )
        assert response.status_code == 200

    def test_departure_time_visible_in_community_drivers(self, client, two_tokens):
        driver_token, _ = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 2, "departure_time": "07:45"}
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {driver_token}"}
        )
        assert response.status_code == 200
        driver = response.json()["drivers"][0]
        assert driver["departure_time"] == "07:45"

    def test_description_visible_in_community_drivers(self, client, two_tokens):
        driver_token, _ = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 2, "description": "Tenho mala grande"}
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {driver_token}"}
        )
        driver = response.json()["drivers"][0]
        assert driver["description"] == "Tenho mala grande"

    def test_departure_time_null_by_default(self, client, two_tokens):
        driver_token, _ = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 2}
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {driver_token}"}
        )
        driver = response.json()["drivers"][0]
        assert driver["departure_time"] is None

    def test_description_null_by_default(self, client, two_tokens):
        driver_token, _ = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 2}
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {driver_token}"}
        )
        driver = response.json()["drivers"][0]
        assert driver["description"] is None

    def test_departure_time_visible_in_passenger_drivers(self, client, two_tokens):
        driver_token, passenger_token = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 2, "departure_time": "08:30"}
        )
        response = client.get(
            "/passenger/drivers",
            headers={"Authorization": f"Bearer {passenger_token}"},
            params={"destination": "FEUP"}
        )
        assert response.status_code == 200
        driver = response.json()["drivers"][0]
        assert driver["departure_time"] == "08:30"

    def test_available_seats_exceeds_max_returns_422(self, client, two_tokens):
        driver_token, _ = two_tokens
        response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 25}
        )
        assert response.status_code == 422


# ---------------------------------------------------------------------------
# 2. Coordenadas GPS em pedidos e ofertas
# ---------------------------------------------------------------------------

class TestGPSCoordinates:

    def test_create_passenger_request_with_coords(self, client, two_tokens):
        _, passenger_token = two_tokens
        response = client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {passenger_token}"},
            json={
                "destination": "FEUP",
                "passenger_count": 1,
                "origin_lat": RESIDENCIA["lat"],
                "origin_lng": RESIDENCIA["lng"]
            }
        )
        assert response.status_code == 200
        assert response.json()["id"] > 0

    def test_create_driver_offer_with_origin_coords(self, client, two_tokens):
        driver_token, _ = two_tokens
        response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={
                "destination": "FEUP",
                "available_seats": 2,
                "origin_lat": RESIDENCIA["lat"],
                "origin_lng": RESIDENCIA["lng"]
            }
        )
        assert response.status_code == 200

    def test_create_driver_offer_with_destination_coords(self, client, two_tokens):
        driver_token, _ = two_tokens
        response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={
                "destination": "FEUP",
                "available_seats": 2,
                "destination_lat": FEUP["lat"],
                "destination_lng": FEUP["lng"]
            }
        )
        assert response.status_code == 200

    def test_create_driver_offer_with_all_coords(self, client, two_tokens):
        driver_token, _ = two_tokens
        response = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={
                "destination": "FEUP",
                "available_seats": 2,
                "origin_lat": RESIDENCIA["lat"],
                "origin_lng": RESIDENCIA["lng"],
                "destination_lat": FEUP["lat"],
                "destination_lng": FEUP["lng"]
            }
        )
        assert response.status_code == 200

    def test_origin_coords_visible_in_community_drivers(self, client, two_tokens):
        driver_token, _ = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={
                "destination": "FEUP",
                "available_seats": 2,
                "origin_lat": RESIDENCIA["lat"],
                "origin_lng": RESIDENCIA["lng"]
            }
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {driver_token}"}
        )
        driver = response.json()["drivers"][0]
        assert driver["origin_lat"] == pytest.approx(RESIDENCIA["lat"], abs=1e-6)
        assert driver["origin_lng"] == pytest.approx(RESIDENCIA["lng"], abs=1e-6)


# ---------------------------------------------------------------------------
# 3. Filtro por raio em /passenger/drivers
# ---------------------------------------------------------------------------

class TestRadiusFilterPassengerDrivers:

    def test_nearby_offer_included_with_radius(self, client, two_tokens):
        driver_token, passenger_token = two_tokens
        # Oferta com destino em FEUP
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={
                "destination": "FEUP",
                "available_seats": 2,
                "destination_lat": FEUP["lat"],
                "destination_lng": FEUP["lng"]
            }
        )
        # Passageiro em Residência, raio 1500 m (FEUP está a ~850 m)
        response = client.get(
            "/passenger/drivers",
            headers={"Authorization": f"Bearer {passenger_token}"},
            params={
                "destination": "FEUP",
                "lat": RESIDENCIA["lat"],
                "lng": RESIDENCIA["lng"],
                "radius_m": 1500
            }
        )
        assert response.status_code == 200
        assert len(response.json()["drivers"]) == 1

    def test_far_offer_excluded_with_radius(self, client, two_tokens):
        driver_token, passenger_token = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={
                "destination": "FEUP",
                "available_seats": 2,
                "destination_lat": FEUP["lat"],
                "destination_lng": FEUP["lng"]
            }
        )
        # Passageiro muito longe, raio 500 m
        response = client.get(
            "/passenger/drivers",
            headers={"Authorization": f"Bearer {passenger_token}"},
            params={
                "destination": "FEUP",
                "lat": FAR["lat"],
                "lng": FAR["lng"],
                "radius_m": 500
            }
        )
        assert response.status_code == 200
        assert len(response.json()["drivers"]) == 0

    def test_radius_m_below_minimum_returns_422(self, client, two_tokens):
        _, passenger_token = two_tokens
        response = client.get(
            "/passenger/drivers",
            headers={"Authorization": f"Bearer {passenger_token}"},
            params={"destination": "FEUP", "radius_m": 50}
        )
        assert response.status_code == 422

    def test_radius_m_above_maximum_returns_422(self, client, two_tokens):
        _, passenger_token = two_tokens
        response = client.get(
            "/passenger/drivers",
            headers={"Authorization": f"Bearer {passenger_token}"},
            params={"destination": "FEUP", "radius_m": 5000}
        )
        assert response.status_code == 422

    def test_no_coords_returns_all_matching_destination(self, client, two_tokens):
        driver_token, passenger_token = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 2}
        )
        response = client.get(
            "/passenger/drivers",
            headers={"Authorization": f"Bearer {passenger_token}"},
            params={"destination": "FEUP"}
        )
        assert response.status_code == 200
        assert len(response.json()["drivers"]) == 1


# ---------------------------------------------------------------------------
# 4. Filtro por raio em /community/drivers
# ---------------------------------------------------------------------------

class TestRadiusFilterCommunityDrivers:

    def test_nearby_driver_included(self, client, two_tokens):
        driver_token, passenger_token = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={
                "destination": "FEUP",
                "available_seats": 2,
                "origin_lat": RESIDENCIA["lat"],
                "origin_lng": RESIDENCIA["lng"]
            }
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {passenger_token}"},
            params={"lat": RESIDENCIA["lat"], "lng": RESIDENCIA["lng"], "radius_m": 100}
        )
        assert response.status_code == 200
        assert len(response.json()["drivers"]) == 1

    def test_far_driver_excluded(self, client, two_tokens):
        driver_token, passenger_token = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={
                "destination": "FEUP",
                "available_seats": 2,
                "origin_lat": RESIDENCIA["lat"],
                "origin_lng": RESIDENCIA["lng"]
            }
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {passenger_token}"},
            params={"lat": FAR["lat"], "lng": FAR["lng"], "radius_m": 500}
        )
        assert response.status_code == 200
        assert len(response.json()["drivers"]) == 0


# ---------------------------------------------------------------------------
# 5. profile_description em /community/drivers e /community/passengers
# ---------------------------------------------------------------------------

class TestProfileDescription:

    def test_unbooked_driver_profile_description(self, client, two_tokens):
        driver_token, _ = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 3}
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {driver_token}"}
        )
        desc = response.json()["drivers"][0]["profile_description"]
        assert "Driver" in desc
        assert "FEUP" in desc
        assert "3" in desc

    def test_booked_driver_profile_description(self, client, two_tokens):
        driver_token, passenger_token = two_tokens
        offer_resp = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 1}
        )
        offer_id = offer_resp.json()["id"]
        client.post(
            "/bookings/driver-offer",
            headers={"Authorization": f"Bearer {passenger_token}"},
            json={"offer_id": offer_id}
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {driver_token}"}
        )
        desc = response.json()["drivers"][0]["profile_description"]
        assert "booked by" in desc
        assert "Passenger" in desc

    def test_booked_driver_has_booked_true(self, client, two_tokens):
        driver_token, passenger_token = two_tokens
        offer_resp = client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 1}
        )
        offer_id = offer_resp.json()["id"]
        client.post(
            "/bookings/driver-offer",
            headers={"Authorization": f"Bearer {passenger_token}"},
            json={"offer_id": offer_id}
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {driver_token}"}
        )
        assert response.json()["drivers"][0]["booked"] is True

    def test_unbooked_driver_has_booked_false(self, client, two_tokens):
        driver_token, _ = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 2}
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {driver_token}"}
        )
        assert response.json()["drivers"][0]["booked"] is False

    def test_unbooked_passenger_profile_description(self, client, two_tokens):
        _, passenger_token = two_tokens
        client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {passenger_token}"},
            json={"destination": "FEUP", "passenger_count": 2}
        )
        response = client.get(
            "/community/passengers",
            headers={"Authorization": f"Bearer {passenger_token}"}
        )
        desc = response.json()["passengers"][0]["profile_description"]
        assert "Passenger" in desc
        assert "2" in desc
        assert "FEUP" in desc

    def test_booked_passenger_profile_description(self, client, two_tokens):
        driver_token, passenger_token = two_tokens
        req_resp = client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {passenger_token}"},
            json={"destination": "FEUP", "passenger_count": 1}
        )
        request_id = req_resp.json()["id"]
        client.post(
            "/bookings/passenger-request",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"request_id": request_id}
        )
        response = client.get(
            "/community/passengers",
            headers={"Authorization": f"Bearer {passenger_token}"}
        )
        desc = response.json()["passengers"][0]["profile_description"]
        assert "booked by" in desc
        assert "Driver" in desc

    def test_booked_passenger_has_booked_true(self, client, two_tokens):
        driver_token, passenger_token = two_tokens
        req_resp = client.post(
            "/passenger/requests",
            headers={"Authorization": f"Bearer {passenger_token}"},
            json={"destination": "FEUP", "passenger_count": 1}
        )
        request_id = req_resp.json()["id"]
        client.post(
            "/bookings/passenger-request",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"request_id": request_id}
        )
        response = client.get(
            "/community/passengers",
            headers={"Authorization": f"Bearer {passenger_token}"}
        )
        assert response.json()["passengers"][0]["booked"] is True

    def test_community_drivers_destination_filter_in_response(self, client, two_tokens):
        driver_token, _ = two_tokens
        client.post(
            "/driver/offers",
            headers={"Authorization": f"Bearer {driver_token}"},
            json={"destination": "FEUP", "available_seats": 2}
        )
        response = client.get(
            "/community/drivers",
            headers={"Authorization": f"Bearer {driver_token}"},
            params={"destination": "FEUP"}
        )
        assert response.json()["destination_filter"] == "FEUP"

    def test_community_passengers_destination_filter_none_when_absent(self, client, two_tokens):
        _, passenger_token = two_tokens
        response = client.get(
            "/community/passengers",
            headers={"Authorization": f"Bearer {passenger_token}"}
        )
        assert response.json()["destination_filter"] is None