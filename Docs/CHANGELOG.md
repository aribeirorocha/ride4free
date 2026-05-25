# Changelog

All notable changes to the Ride4Free project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Release v3] - 2026-05-25 (End of Sprint 3)

### 🎯 Release Value Summary
This final release elevates Ride4Free to a production-ready state. We introduced real-time bidirectional communication, allowing drivers and passengers to coordinate seamlessly. To break free from local development limitations, we successfully deployed the FastAPI backend globally using Cloudflare Tunnels. Furthermore, the UI underwent a deep structural refactoring and beautification, ensuring robust testability, flawless error handling, and a highly polished user experience.

### Added (Closed PBIs)
* **[US6] In-App Chat (Real-Time Communication):** Implemented a bidirectional messaging system. Users can now use a 1-to-1 chat to coordinate meeting points during the booking phase (Join Requests), and a Group Chat feature for active rides involving multiple passengers.
* **Remote Server Infrastructure (DevOps):** Migrated the backend from `localhost` to a globally accessible remote server via a **Cloudflare Tunnel Reverse Proxy**. This enables real device testing over mobile networks (4G/5G) and eliminates cross-OS network discrepancies.
* **Empty Message Prevention:** Built-in UI validation that dynamically disables the chat send button if the input field is empty or contains only whitespaces.

### Changed
* **UI/UX Refactoring & Modularization:** Extracted deeply nested private widgets (e.g., `InfoExtraWidget`, Chat BottomSheets) into standalone, testable public components. This significantly improves visual consistency ("beautification") and enforces the Single Responsibility Principle.
* **Test Suite Mocking Strategy:** Upgraded the testing infrastructure to heavily rely on Dependency Injection with `MockClient`. This completely isolates UI behavior validation from network latency and remote server fluctuations, ensuring a reliable CI/CD pipeline.

### Fixed
* **Asynchronous UI Rendering Conflicts:** Resolved flaky tests and UI crashes related to rapid asynchronous state changes (e.g., `ScaffoldMessenger` overlapping). Implemented precise timing and pumping mechanisms in the widget test suite.
* **Message Send Failure Handling:** Implemented robust `try/catch` blocks in the chat flow to gracefully handle API or network failures, displaying a clear Error Snackbar to the user without crashing the active ride state.

---

## [Release v2] - 2026-05-11 (End of Sprint 2)

### 🎯 Release Value Summary
This release marks the transition of Ride4Free from a static prototype to a fully functional platform. End-users can now securely authenticate using their U.Porto Sigarra credentials, dynamically offer rides to earn credits, and search for available drivers using interactive map filters powered by geolocation. The underlying architecture has been fully integrated with a custom FastAPI backend and a relational SQLite database, ensuring real-time data persistence, spatial querying, and a robust foundation for future scaling.

### Added (Closed PBIs)
* **[US5] Sigarra Authentication Integration:** Implemented a secure Single Sign-On (SSO) flow specific to university credentials. The system communicates directly with sigarra.up.pt to extract the user's name, profile photo, and institutional ID, seamlessly bridging this identity with a local shadow account in the FastAPI backend.
* **[US1] Ride Publishing & Interactive Coordinate Selection:** Users can now offer rides through the OfferRidePage. This includes an embedded CartoDB dark-themed FlutterMap allowing drivers to pinpoint exact departure and arrival coordinates. The system dynamically calculates credit rewards (+10 Credits per seat) and validates departure time formats (HH:mm).
* **[US2 & US3] Advanced Spatial Ride Searching:** Integrated an interactive map interface (SearchRidePage) allowing users to find rides based on a configurable distance tolerance slider (100m to 2000m). Filtering is backed by the mathematical Haversine formula on the SQLite backend to accurately calculate real-world distances between the passenger and available drivers.
* **Reverse Geocoding (Nominatim):** Integrated OpenStreetMap's Nominatim API to translate raw GPS coordinates into human-readable street names for passenger pickups.
* **Real-Time Community Board:** Added a community dashboard with separate tabs for Drivers and Passengers, featuring an automated polling mechanism that refreshes data every 3 seconds to keep ride statuses strictly up to date.

### Changed
* **Backend API Client Integration:** Replaced static UI mocks with the Ride4FreeApi HTTP client. It natively handles Bearer token authorization and dynamically routes traffic to 10.0.2.2 (Android Emulator) or localhost (Web/iOS) based on the running platform.
* **State Management:** Refactored session handling into a dedicated UniversitySessionStore (using SharedPreferences) to properly manage identity lifecycles and backend token synchronization.
* **Database Schema Robustness:** Transitioned to a strictly relational SQLite schema featuring users, sessions, passenger_requests, driver_offers, and ride_bookings with full ON DELETE CASCADE foreign-key support and cryptographic PBKDF2 password hashing.

### Fixed
* **Test Suite Regex Matching:** Resolved asynchronous state conflicts and RichText rendering discrepancies in the Flutter UI integration tests by implementing deep widget tree querying (findRichText: true) and robust Regular Expressions (RegExp).
* **Database Locks:** Implemented Python context managers (@contextmanager) in the backend to ensure SQLite database connections are gracefully committed and closed, preventing thread locks during parallel test execution.
