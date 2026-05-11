
# Changelog

All notable changes to the **Ride4Free** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Release v2] - 2026-05-11 (End of Sprint 2)

### 🎯 Release Value Summary
This release marks the transition of Ride4Free from a static prototype to a fully functional platform. **End-users can now securely authenticate using their University credentials, dynamically offer rides to earn credits, and search for available drivers using interactive map filters.** The underlying architecture has been fully integrated with a FastAPI backend and SQLite database, ensuring real-time data persistence and a robust foundation for future scaling.

### Added (Closed PBIs)
* **[US5] University Authentication Integration:** Implemented a secure Single Sign-On (SSO) flow specific to university credentials, decoupling it from generic login systems for enhanced security.
* **[US1] Ride Publishing & Reward System:** Users can now offer rides through the `OfferRidePage`. The system dynamically calculates credit rewards based on the number of available seats selected.
* **[US2 & US3] Advanced Ride Searching & Filtering:** Integrated an interactive map interface (`SearchRidePage`) allowing users to find rides based on a configurable distance tolerance radius (slider) and specific destination points.
* **API Mocking Infrastructure:** Integrated the `mocktail` framework to simulate backend HTTP responses, ensuring the UI can be rigorously and predictably tested in CI/CD pipelines without network interference.

### Changed
* **Backend Integration:** Replaced static UI mocks with live HTTP calls communicating with the FastAPI Python server.
* **State Management:** Refactored the generic session handling into a dedicated `UniversitySessionStore` to properly manage user identity and token lifecycles.
* **UI/UX Improvements:** Replaced simple ListViews with Scrollable components in the forms to resolve RenderFlex overflow issues on smaller devices.

### Fixed
* Resolved asynchronous state conflicts in the Flutter UI (Timer and `pumpAndSettle` issues) that caused race conditions when rapidly changing seat capacities.
* Fixed widget layout issues where the `RewardPanel` text rich formatting caused rendering discrepancies.
