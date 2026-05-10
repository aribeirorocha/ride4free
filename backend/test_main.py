"""
Integration tests for main.py — FastAPI endpoints for Ride4Free.
"""

import os
import tempfile
import pytest
from fastapi.testclient import TestClient

# Setup temp DB before importing main
@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    """Setup temporary database for all tests."""
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    os.environ["RIDE4FREE_DB_PATH"] = path
    yield path
    if os.path.exists(path):
        os.unlink(path)


@pytest.fixture
def client():
    """Provide a TestClient for each test."""
    from main import app
    import database as db
    from importlib import reload
    
    # Reload to pick up new DB path
    reload(db)
    
    # Initialize DB for this test
    db.init_db()
    
    return TestClient(app)


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
        response = client.get(
            "/passenger/drivers",
            headers={"Authorization": f"Bearer {auth_token}"},
            params={"destination": ""}
        )
        
        assert response.status_code == 400


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
