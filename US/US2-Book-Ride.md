### Statement
As a Student Passenger, I want to book a ride and be rated positively so that I can earn bonus credits and continue using the system even without a car.

### Business Value
Facilitates student commuting without financial costs, promoting mutual aid and sustainability.

### Acceptance Tests
* **Scenario: Successful Booking**
  * **Given** the passenger finds a trip and has a sufficient credit balance.
  * **When** they click "Book Seat Now".
  * **Then** the system deducts 10 credits from their balance and confirms the booking instantly.

* **Scenario: Insufficient Balance**
  * **Given** the passenger tries to book a 10-credit trip but only has 0 or 5 credits.
  * **When** they attempt to confirm the booking.
  * **Then** the system prevents the action and displays an "Insufficient Credit Balance" message.

**Priority:** Must-have  
**Effort:** 5 points
