"""
Extended unit tests for API endpoints — Ride management, offers, and requests.
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
def auth_headers(client):
    """Create a test user and return auth headers."""
    response = client.post(
        "/users/register",
        json={"email": "driver@test.com", "password": "password123", "name": "Driver"}
    )
    token = response.json()["token"]
    return {"Authorization": f"Bearer {token}"}


class TestDriverOffers:
    """Tests for driver offer endpoints."""
    
    def test_create_driver_offer_success(self, client, auth_headers):
        response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "available_seats": 3,
                "departure_time": "08:15",
                "description": "Starting from North Campus",
                "vehicle_info": "Toyota Corolla - White",
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["offer_id"] is not None
        assert data["available_seats"] == 3
    
    def test_create_driver_offer_no_seats(self, client, auth_headers):
        response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "available_seats": 0,
                "departure_time": "08:15",
                "description": "Starting point",
            }
        )
        
        assert response.status_code == 422
    
    def test_create_driver_offer_negative_seats(self, client, auth_headers):
        response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "available_seats": -5,
                "departure_time": "08:15",
                "description": "Starting point",
            }
        )
        
        assert response.status_code == 422
    
    def test_create_driver_offer_invalid_time_format(self, client, auth_headers):
        response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "available_seats": 3,
                "departure_time": "25:99",  # Invalid time
                "description": "Starting point",
            }
        )
        
        assert response.status_code == 422
    
    def test_create_driver_offer_with_location_coordinates(self, client, auth_headers):
        response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "available_seats": 3,
                "departure_time": "08:15",
                "description": "Starting from North",
                "origin_lat": 41.1780,
                "origin_lng": -8.5980,
                "destination_lat": 40.5000,
                "destination_lng": -8.0000,
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["offer_id"] is not None
    
    def test_list_available_drivers(self, client, auth_headers):
        # First create an offer
        client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "available_seats": 3,
                "departure_time": "08:15",
                "description": "Starting point",
            }
        )
        
        # Then list drivers
        response = client.get(
            "/community/drivers",
            headers=auth_headers,
            params={"destination": "FEUP"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "drivers" in data
        assert len(data["drivers"]) >= 1
    
    def test_list_drivers_empty_destination(self, client, auth_headers):
        response = client.get(
            "/community/drivers",
            headers=auth_headers,
            params={"destination": "NonexistentPlace"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "drivers" in data
        assert len(data["drivers"]) == 0
    
    def test_list_drivers_with_radius(self, client, auth_headers):
        # Create offer with coordinates
        client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "available_seats": 3,
                "departure_time": "08:15",
                "description": "Starting point",
                "origin_lat": 41.1780,
                "origin_lng": -8.5980,
            }
        )
        
        # Query with radius
        response = client.get(
            "/community/drivers",
            headers=auth_headers,
            params={
                "destination": "FEUP",
                "lat": 41.1780,
                "lng": -8.5980,
                "radius_m": 5000,
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "drivers" in data
    
    def test_list_drivers_without_auth(self, client):
        response = client.get(
            "/community/drivers",
            params={"destination": "FEUP"}
        )
        
        assert response.status_code == 401
    
    def test_get_active_ride_state_no_active_ride(self, client, auth_headers):
        response = client.get(
            "/rides/active",
            headers=auth_headers
        )
        
        assert response.status_code in [200, 404]
    
    def test_offer_too_many_seats(self, client, auth_headers):
        response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "available_seats": 1000,  # Unrealistic
                "departure_time": "08:15",
                "description": "Starting point",
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["available_seats"] == 1000
    
    def test_empty_destination_name(self, client, auth_headers):
        response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "",
                "available_seats": 3,
                "departure_time": "08:15",
                "description": "Starting point",
            }
        )
        
        assert response.status_code == 422
    
    def test_special_characters_in_destination(self, client, auth_headers):
        response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "Café São Bento & Maria's",
                "available_seats": 3,
                "departure_time": "08:15",
                "description": "Starting point",
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["offer_id"] is not None


class TestPassengerRequests:
    """Tests for passenger request endpoints."""
    
    def test_create_passenger_request_success(self, client, auth_headers):
        response = client.post(
            "/requests/create-request",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "passenger_count": 2,
                "origin_lat": 41.1780,
                "origin_lng": -8.5980,
                "origin_display": "Livraria",
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["request_id"] is not None
        assert data["passenger_count"] == 2
    
    def test_create_passenger_request_zero_passengers(self, client, auth_headers):
        response = client.post(
            "/requests/create-request",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "passenger_count": 0,
                "origin_display": "Livraria",
            }
        )
        
        assert response.status_code == 422
    
    def test_create_passenger_request_negative_passengers(self, client, auth_headers):
        response = client.post(
            "/requests/create-request",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "passenger_count": -1,
                "origin_display": "Livraria",
            }
        )
        
        assert response.status_code == 422
    
    def test_list_available_passengers(self, client, auth_headers):
        # Create a passenger request
        client.post(
            "/requests/create-request",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "passenger_count": 2,
                "origin_display": "Downtown",
            }
        )
        
        # List passengers
        response = client.get(
            "/community/passengers",
            headers=auth_headers,
            params={"destination": "FEUP"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "passengers" in data
        assert len(data["passengers"]) >= 1
    
    def test_list_passengers_empty(self, client, auth_headers):
        response = client.get(
            "/community/passengers",
            headers=auth_headers,
            params={"destination": "NonexistentPlace"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "passengers" in data
        assert len(data["passengers"]) == 0
    
    def test_list_passengers_for_destination(self, client, auth_headers):
        response = client.get(
            "/search/passengers-for-destination",
            headers=auth_headers,
            params={"destination": "FEUP"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "requests" in data or "passengers" in data or "rows" in data
    
    def test_list_drivers_for_destination(self, client, auth_headers):
        response = client.get(
            "/search/drivers-for-destination",
            headers=auth_headers,
            params={
                "destination": "FEUP",
                "lat": 41.1780,
                "lng": -8.5980,
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "drivers" in data or "rows" in data


class TestBookings:
    """Tests for booking endpoints."""
    
    def test_book_driver_offer_success(self, client, auth_headers):
        # Create offer
        offer_response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "available_seats": 3,
                "departure_time": "08:15",
                "description": "Starting point",
            }
        )
        
        offer_id = offer_response.json()["offer_id"]
        
        # Create second user
        user_response = client.post(
            "/users/register",
            json={"email": "passenger@test.com", "password": "password123", "name": "Passenger"}
        )
        passenger_token = user_response.json()["token"]
        passenger_headers = {"Authorization": f"Bearer {passenger_token}"}
        
        # Book
        response = client.post(
            "/bookings/request-join-ride",
            headers=passenger_headers,
            json={"offer_id": offer_id}
        )
        
        assert response.status_code in [200, 201]
    
    def test_book_nonexistent_offer(self, client, auth_headers):
        response = client.post(
            "/bookings/request-join-ride",
            headers=auth_headers,
            json={"offer_id": 99999}
        )
        
        assert response.status_code == 404
    
    def test_book_passenger_request(self, client, auth_headers):
        # Create passenger request
        req_response = client.post(
            "/requests/create-request",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                "passenger_count": 2,
                "origin_display": "Downtown",
            }
        )
        
        request_id = req_response.json()["request_id"]
        
        # Create second user
        user_response = client.post(
            "/users/register",
            json={"email": "driver2@test.com", "password": "password123", "name": "Driver 2"}
        )
        driver_token = user_response.json()["token"]
        driver_headers = {"Authorization": f"Bearer {driver_token}"}
        
        # Book passenger
        response = client.post(
            "/bookings/book-passenger",
            headers=driver_headers,
            json={"request_id": request_id}
        )
        
        assert response.status_code in [200, 201, 404]


class TestRideStatus:
    """Tests for ride status endpoints."""
    
    def test_get_database_schema(self, client, auth_headers):
        response = client.get(
            "/database/schema",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "tables" in data or "status" in data
    
    def test_health_check(self, client):
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
    
    def test_get_user_profile(self, client, auth_headers):
        response = client.get(
            "/users/profile",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "id" in data
        assert "email" in data
        assert "name" in data
    
    def test_update_vehicle_info(self, client, auth_headers):
        response = client.put(
            "/users/vehicle-info",
            headers=auth_headers,
            json={"vehicle_info": "Tesla Model 3 - White"}
        )
        
        assert response.status_code == 200
    
    def test_get_vehicle_info(self, client, auth_headers):
        # First update
        client.put(
            "/users/vehicle-info",
            headers=auth_headers,
            json={"vehicle_info": "Toyota Corolla"}
        )
        
        # Then retrieve
        response = client.get(
            "/users/profile",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["vehicle_info"] == "Toyota Corolla"


class TestErrorHandling:
    """Tests for error handling and edge cases."""
    
    def test_missing_auth_header(self, client):
        response = client.get("/users/profile")
        
        assert response.status_code == 401
    
    def test_invalid_auth_token(self, client):
        response = client.get(
            "/users/profile",
            headers={"Authorization": "Bearer invalid_token_xyz"}
        )
        
        assert response.status_code == 401
    
    def test_malformed_auth_header(self, client):
        response = client.get(
            "/users/profile",
            headers={"Authorization": "NotABearerToken"}
        )
        
        assert response.status_code == 401
    
    def test_missing_required_fields_in_offer(self, client, auth_headers):
        response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            json={
                "destination": "FEUP",
                # Missing: available_seats, departure_time, description
            }
        )
        
        assert response.status_code == 422
    
    def test_invalid_json_body(self, client, auth_headers):
        response = client.post(
            "/offers/create-offer",
            headers=auth_headers,
            data="not valid json {",
            content_type="application/json"
        )
        
        assert response.status_code in [400, 422]
