### Statement
As a Driver, I want to rate my passengers after a trip so that the community stays safe and the passenger can be rewarded with bonus points for good behavior.

### Business Value
Encourages a respectful community and high-quality service. The point system (gamification) increases user retention and app engagement.

### Acceptance Tests
* **Scenario: Successful Rating**
  * **Given** a trip has just been completed.
  * **When** the driver selects a 5-star rating and clicks "Submit".
  * **Then** the system confirms the rating.
  * **And** the passenger receives +5 bonus points for their "Good Conduct" streak.

* **Scenario: Reporting Bad Behavior**
  * **Given** a passenger was late or disrespectful.
  * **When** the driver gives a 1-star rating and adds a comment.
  * **Then** the system flags the passenger's profile for review.
  * **And** no bonus points are awarded for that trip.

**Priority:** Could-have
**Effort:** 3 points
