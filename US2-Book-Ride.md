### Statement
[cite_start]As a Student Passenger, I want to book a ride and be rated positively so that I can earn bonus credits and continue using the system even without a car.

### Business Value
[cite_start]Facilitates student commuting without financial costs, promoting mutual aid and sustainability.

### Acceptance Tests
* **Scenario: Successful Booking**
  * [cite_start]**Given** the passenger finds a trip and has a sufficient credit balance.
  * [cite_start]**When** they click "Book Seat Now".
  * [cite_start]**Then** the system deducts 10 credits from their balance and confirms the booking instantly.

* **Scenario: Insufficient Balance**
  * [cite_start]**Given** the passenger tries to book a 10-credit trip but only has 0 or 5 credits.
  * [cite_start]**When** they attempt to confirm the booking.
  * [cite_start]**Then** the system prevents the action and displays an "Insufficient Credit Balance" message.

**Priority:** Must-have  
**Effort:** 5 points
