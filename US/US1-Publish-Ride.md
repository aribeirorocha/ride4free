### Statement
As a Student Driver, I want to publish my trip to the university so that I can earn mobility credits to use when I need a ride myself.

### Business Value
Ensures a steady supply of drivers by providing an incentive system through credit accumulation for future use.

### Acceptance Tests
* **Scenario: Successful Publication**
  * **Given** the driver has entered the starting point, destination, and time.
  * **And** specified how many available seats.
  * **When** they click "Publish Trip".
  * **Then** the system validates the data and shows an estimated reward of +30 credits.
* **Mockup**
  * <img width="200" height="300" alt="image" src="https://github.com/user-attachments/assets/a325f576-0aa7-4cd6-9a63-1a52a242e84b" />

  


* **Scenario: Invalid Capacity**
  * **Given** the driver enters the route but keeps seats at 0.
  * **When** they attempt to publish the trip].
  * **Then** the system prevents publication and displays an "Invalid Capacity" warning.
* **Mockup**
  * <img width="200" height="300" alt="image" src="https://github.com/user-attachments/assets/bf874088-dc0a-4753-adb6-792d6227496e" />



**Priority:** Must-have  
**Effort:** 5 points
