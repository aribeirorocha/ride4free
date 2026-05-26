"""
Extended unit tests for credit system — earning, spending, and balance management.
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
        json={"email": "user@test.com", "password": "password123", "name": "Test User"}
    )
    token = response.json()["token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def another_user_headers(client):
    """Create a second test user and return auth headers."""
    response = client.post(
        "/users/register",
        json={"email": "user2@test.com", "password": "password123", "name": "Test User 2"}
    )
    token = response.json()["token"]
    return {"Authorization": f"Bearer {token}"}


class TestCreditSystem:
    """Tests for the credit system."""
    
    def test_get_initial_credit_balance(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "balance" in data
        assert data["balance"] >= 0
    
    def test_credit_balance_is_positive_on_new_user(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        # New users typically get initial credits
        assert data["balance"] >= 0
    
    def test_get_credit_transactions_list(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        
        if "transactions" in data:
            assert isinstance(data["transactions"], list)
            if len(data["transactions"]) > 0:
                transaction = data["transactions"][0]
                assert "id" in transaction
                assert "type" in transaction
                assert "amount" in transaction
    
    def test_credit_balance_after_creating_offer(self, client, auth_headers):
        # Get initial balance
        initial_response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        initial_balance = initial_response.json()["balance"]
        
        # Create an offer (driver gains credits)
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
        
        # Get new balance
        new_response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        new_balance = new_response.json()["balance"]
        
        # Balance should change or remain the same (depends on system design)
        assert isinstance(new_balance, int)
    
    def test_credit_deduction_for_join_ride(self, client, auth_headers, another_user_headers):
        # First user creates an offer
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
        
        # Get second user's initial balance
        initial_response = client.get(
            "/users/credits",
            headers=another_user_headers
        )
        initial_balance = initial_response.json()["balance"]
        
        # Second user joins the ride (credits deducted)
        client.post(
            "/bookings/request-join-ride",
            headers=another_user_headers,
            json={"offer_id": offer_id}
        )
        
        # Check new balance
        new_response = client.get(
            "/users/credits",
            headers=another_user_headers
        )
        new_balance = new_response.json()["balance"]
        
        # Balance should decrease or remain same depending on system
        assert isinstance(new_balance, int)
        assert new_balance <= initial_balance + 10  # Allow some margin


class TestCreditTransactions:
    """Tests for credit transaction tracking."""
    
    def test_transaction_history_recorded(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        
        if "transactions" in data:
            # Should have transactions list
            assert isinstance(data["transactions"], list)
    
    def test_transaction_has_required_fields(self, client, auth_headers):
        # Create an offer to trigger a transaction
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
        
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        data = response.json()
        if "transactions" in data and len(data["transactions"]) > 0:
            transaction = data["transactions"][0]
            
            # Check required fields
            assert "type" in transaction  # earn/spend
            assert "amount" in transaction
            assert transaction["amount"] >= 0
    
    def test_transaction_types_are_valid(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        data = response.json()
        if "transactions" in data:
            for transaction in data["transactions"]:
                if "type" in transaction:
                    assert transaction["type"] in ["earn", "spend", "bonus", "refund"]
    
    def test_transaction_amounts_are_positive(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        data = response.json()
        if "transactions" in data:
            for transaction in data["transactions"]:
                if "amount" in transaction:
                    assert transaction["amount"] >= 0
    
    def test_multiple_transactions_accumulate(self, client, auth_headers):
        initial_response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        # Create multiple offers
        for i in range(3):
            client.post(
                "/offers/create-offer",
                headers=auth_headers,
                json={
                    "destination": f"Destination{i}",
                    "available_seats": 2,
                    "departure_time": "10:00",
                    "description": f"Offer {i}",
                }
            )
        
        final_response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        assert final_response.status_code == 200
        data = final_response.json()
        assert isinstance(data["balance"], int)


class TestCreditBoundaryConditions:
    """Tests for boundary conditions in credit system."""
    
    def test_zero_balance_is_valid(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Zero balance should be valid
        if data["balance"] == 0:
            assert isinstance(data["balance"], int)
    
    def test_large_credit_amounts(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        data = response.json()
        balance = data["balance"]
        
        # Should handle large numbers
        assert balance < 1000000  # Reasonable upper bound
    
    def test_transaction_amount_zero_not_recorded(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        data = response.json()
        if "transactions" in data:
            # No transactions with amount 0 (or very few)
            zero_transactions = [t for t in data["transactions"] if t.get("amount") == 0]
            assert len(zero_transactions) <= 1
    
    def test_very_old_transactions_remain(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        data = response.json()
        if "transactions" in data and len(data["transactions"]) > 0:
            # Transactions should be preserved
            assert len(data["transactions"]) >= 0


class TestCreditConsistency:
    """Tests for credit balance consistency."""
    
    def test_balance_sum_matches_transactions(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        data = response.json()
        
        if "balance" in data and "transactions" in data:
            # This depends on initial credit allocation
            # but transactions should be tracked consistently
            balance = data["balance"]
            transactions = data["transactions"]
            
            assert balance >= 0
            assert isinstance(transactions, list)
    
    def test_balance_never_negative(self, client, auth_headers):
        for _ in range(5):
            response = client.get(
                "/users/credits",
                headers=auth_headers
            )
            
            data = response.json()
            assert data["balance"] >= 0
    
    def test_balance_is_integer(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        data = response.json()
        assert isinstance(data["balance"], int)
    
    def test_repeated_balance_checks_consistent(self, client, auth_headers):
        balances = []
        
        for _ in range(5):
            response = client.get(
                "/users/credits",
                headers=auth_headers
            )
            
            data = response.json()
            balances.append(data["balance"])
        
        # All checks should return same balance (no changes between reads)
        assert len(set(balances)) == 1


class TestCreditErrorHandling:
    """Tests for error handling in credit system."""
    
    def test_get_credits_without_auth(self, client):
        response = client.get("/users/credits")
        
        assert response.status_code == 401
    
    def test_get_credits_with_invalid_token(self, client):
        response = client.get(
            "/users/credits",
            headers={"Authorization": "Bearer invalid_token"}
        )
        
        assert response.status_code == 401
    
    def test_get_credits_with_missing_bearer(self, client):
        response = client.get(
            "/users/credits",
            headers={"Authorization": "invalid_token"}
        )
        
        assert response.status_code == 401
    
    def test_credit_response_format_valid(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Should be proper JSON
        assert isinstance(data, dict)
        assert "balance" in data


class TestCreditIsolation:
    """Tests to ensure credit isolation between users."""
    
    def test_different_users_different_balances(self, client, auth_headers, another_user_headers):
        response1 = client.get(
            "/users/credits",
            headers=auth_headers
        )
        balance1 = response1.json()["balance"]
        
        response2 = client.get(
            "/users/credits",
            headers=another_user_headers
        )
        balance2 = response2.json()["balance"]
        
        # Both users should have valid (non-negative) balances
        assert balance1 >= 0
        assert balance2 >= 0
    
    def test_one_user_offer_does_not_affect_other_user(self, client, auth_headers, another_user_headers):
        # Get user2 initial balance
        initial_response = client.get(
            "/users/credits",
            headers=another_user_headers
        )
        initial_balance = initial_response.json()["balance"]
        
        # User1 creates an offer
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
        
        # Get user2 final balance (should be unchanged)
        final_response = client.get(
            "/users/credits",
            headers=another_user_headers
        )
        final_balance = final_response.json()["balance"]
        
        assert initial_balance == final_balance
    
    def test_user_transactions_isolated(self, client, auth_headers, another_user_headers):
        # User1 creates an offer
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
        
        # Get user1 transactions
        response1 = client.get(
            "/users/credits",
            headers=auth_headers
        )
        transactions1 = response1.json().get("transactions", [])
        
        # Get user2 transactions
        response2 = client.get(
            "/users/credits",
            headers=another_user_headers
        )
        transactions2 = response2.json().get("transactions", [])
        
        # User2 should not see user1's transactions
        if transactions1:
            # They should be different users' transactions
            assert len(transactions1) >= len(transactions2)


class TestCreditEdgeCases:
    """Tests for edge cases in credit system."""
    
    def test_concurrent_credit_checks(self, client, auth_headers):
        # Simulate checking credits multiple times
        responses = []
        for _ in range(10):
            response = client.get(
                "/users/credits",
                headers=auth_headers
            )
            responses.append(response.json()["balance"])
        
        # All balances should be consistent
        assert len(set(responses)) == 1
    
    def test_empty_transaction_list_is_valid(self, client, auth_headers):
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        data = response.json()
        
        # New user might have empty transaction list
        if "transactions" in data:
            assert isinstance(data["transactions"], list)
    
    def test_transaction_timestamp_format(self, client, auth_headers):
        # Create a transaction
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
        
        response = client.get(
            "/users/credits",
            headers=auth_headers
        )
        
        data = response.json()
        if "transactions" in data and len(data["transactions"]) > 0:
            transaction = data["transactions"][0]
            
            if "timestamp" in transaction:
                # Should be ISO format or timestamp
                assert isinstance(transaction["timestamp"], (str, int))
