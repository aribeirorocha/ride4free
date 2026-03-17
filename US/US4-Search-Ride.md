### Statement
As a **passenger**, I want to search for a liftshare ride from my pickup point to my destination with a defined **walking tolerance** so that I can find more travel options even if the driver's route does not pass exactly at my door.

### Business Value
This feature is essential to increase the matching rate between drivers and passengers. By allowing a small detour on foot, we attract eco-conscious users and grow the user base by making the system more flexible.

### Assumptions / Dependencies
- User is logged in.
- GPS/Location services are enabled on the phone.
- Internet connection is required.

### Acceptance Tests
* **Scenario: Successful Match within Radius**
  * **Given** the passenger enters a starting point and a destination.
  * **And** sets a maximum walking distance (e.g., 500m) using a slider.
  * **When** the app searches for drivers traveling in the same direction.
  * **Then** it displays available rides where the driver passes within the 500m radius of the requested points.

* **Mockup:**

  <img width="200" height="400" alt="image" src="https://github.com/user-attachments/assets/c2c7e2a7-6021-47ac-8fe5-00fa2214cb57" />

* **Scenario: No Matching Drivers**
  * **Given** the passenger sets their search criteria.
  * **When** no drivers match the route or walking tolerance.
  * **Then** the app shows a "No lifts available now" message.
  * **And** provides options like "Retry" or "Notify me when available".
* **Mockup:**
  
  <img width="200" height="400" alt="image" src="https://github.com/user-attachments/assets/f66c3183-9509-48bf-97d6-d990031c7572" />






**Priority:** Should-have  
**Effort:** 3 points
