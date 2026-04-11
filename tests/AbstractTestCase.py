"""
Abstract Test Case for Ride4Free Project
Base class for all test scenarios covering:
- US1: Publish Ride
- US2: Book Ride
- US3: Rate Passengers
- US4: Search Ride
"""

from abc import ABC, abstractmethod
from enum import Enum
from dataclasses import dataclass
from datetime import datetime
from typing import Optional


class UserRole(Enum):
    """User roles in the Ride4Free system"""
    DRIVER = "driver"
    PASSENGER = "passenger"


class RideStatus(Enum):
    """Possible ride statuses"""
    PUBLISHED = "published"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


@dataclass
class User:
    """Represents a user in the system"""
    id: str
    name: str
    email: str
    role: UserRole
    credits: int = 0
    rating: float = 5.0


@dataclass
class Location:
    """Represents a geographical location"""
    latitude: float
    longitude: float
    address: str


@dataclass
class Ride:
    """Represents a ride/trip"""
    id: str
    driver: User
    start_location: Location
    end_location: Location
    departure_time: datetime
    available_seats: int
    status: RideStatus = RideStatus.PUBLISHED
    passengers: list = None
    credit_reward: int = 30

    def __post_init__(self):
        if self.passengers is None:
            self.passengers = []


class AbstractTestCase(ABC):
    """
    Abstract base class for all Ride4Free test cases.
    Provides common setup, teardown, and utility methods.
    """

    def __init__(self):
        """Initialize test fixtures"""
        self.test_driver = None
        self.test_passenger = None
        self.test_ride = None
        self.setup()

    def setup(self):
        """Setup test fixtures before each test"""
        self.test_driver = User(
            id="driver_001",
            name="John Driver",
            email="john@example.com",
            role=UserRole.DRIVER,
            credits=100
        )

        self.test_passenger = User(
            id="passenger_001",
            name="Jane Passenger",
            email="jane@example.com",
            role=UserRole.PASSENGER,
            credits=50
        )

        self.test_ride = Ride(
            id="ride_001",
            driver=self.test_driver,
            start_location=Location(40.7128, -74.0060, "New York"),
            end_location=Location(40.7580, -73.9855, "Times Square"),
            departure_time=datetime(2026, 3, 20, 14, 30),
            available_seats=3
        )

    def teardown(self):
        """Cleanup after each test"""
        self.test_driver = None
        self.test_passenger = None
        self.test_ride = None

    # Assertion helpers
    def assert_user_has_credits(self, user: User, expected_credits: int):
        """Assert that user has expected credits"""
        assert user.credits == expected_credits, \
            f"Expected {expected_credits} credits, got {user.credits}"

    def assert_ride_is_published(self, ride: Ride):
        """Assert that ride is in published state"""
        assert ride.status == RideStatus.PUBLISHED, \
            f"Expected ride status PUBLISHED, got {ride.status}"

    def assert_ride_has_seats(self, ride: Ride, expected_seats: int):
        """Assert that ride has expected available seats"""
        assert ride.available_seats == expected_seats, \
            f"Expected {expected_seats} seats, got {ride.available_seats}"

    def assert_passenger_in_ride(self, ride: Ride, passenger: User):
        """Assert that passenger is booked in the ride"""
        assert passenger in ride.passengers, \
            f"Passenger {passenger.name} not found in ride {ride.id}"

    def assert_user_rating(self, user: User, expected_rating: float):
        """Assert that user has expected rating"""
        assert user.rating == expected_rating, \
            f"Expected rating {expected_rating}, got {user.rating}"

    # Abstract test methods - to be implemented by subclasses
    @abstractmethod
    def test_main_scenario(self):
        """Main test scenario - must be implemented by subclass"""
        pass

    @abstractmethod
    def test_error_scenario(self):
        """Error/validation scenario - must be implemented by subclass"""
        pass

    def run_tests(self):
        """Execute all test methods"""
        try:
            print(f"\nRunning {self.__class__.__name__}...")
            self.test_main_scenario()
            print(f"  ✓ Main scenario passed")
            self.teardown()

            self.setup()
            self.test_error_scenario()
            print(f"  ✓ Error scenario passed")
            self.teardown()

            print(f"{self.__class__.__name__} - All tests passed!\n")
        except AssertionError as e:
            print(f"  ✗ Test failed: {e}\n")
            raise


# Example usage / Test runner
if __name__ == "__main__":
    print("Ride4Free Abstract Test Framework")
    print("=" * 50)
    print("This is the base test class for the Ride4Free project.")
    print("Create subclasses to test specific user stories.\n")




