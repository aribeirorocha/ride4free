# Execution Report: Sprint 1 — Ride4Free 

## 1. Sprint Review
**Demonstration of the Product Increment:**
In this iteration, the team executed the critical transition from a static Mock Widget interface (Sprint 0) to a fully functional, integrated system. We demonstrated seamless communication between the Flutter client and the FastAPI (Python) server, supported by an SQLite database. The delivered features included the complete authentication flow (registration/login via Bearer tokens), ride offering with dynamic credit reward calculation, and ride searching with distance tolerance filtering.

**Feedback and Adaptation:**
The comprehensive test coverage (approximately 90 passing Unit, Integration, and Acceptance tests) was identified as the stability pillar of the project. However, we observed that the Flutter test environment automatically blocks real HTTP requests for security reasons, causing visual exceptions in the map component logs. As an adaptation, the Product Backlog was updated to include "API Mocking for Tests" (via the `mocktail` package) for Sprint 2, ensuring a cleaner CI/CD test environment.

---

## 2. Sprint Planning & Organization
**Effort Planning:**
During the Sprint Planning session, based on the velocity recorded in Sprint 0, the team committed to a total of **33 effort points** for this two-week work cycle. This capacity reflects the full implementation of **US1 (Publish Ride)** and **US2 (Book Ride)**, including the necessary backend infrastructure to support both workflows.

**Team Structure and Milestones:**
To optimize parallel development, the team divided into two functional subgroups coordinated via GitHub Milestones:

1. **Quality & Verification Subgroup (2 members):** Responsible for developing the test suite (ATDD, Unit, and Integration tests). Their focus was to ensure the increment strictly met the *Definition of Done* through rigorous behavior validation.
2. **Development & Product Subgroup (3 members):** Responsible for implementing the Product Increment, covering the business logic in FastAPI, SQLite persistence, and the reactive UI in Flutter.

*Milestones* served as vital synchronization points, ensuring the backend endpoints were fully functional by the end of the first week, which allowed for seamless frontend integration during the second week.

---

## 3. Agile Patterns Applied
* **Sprint Backlog:** Items were explicitly moved from the Product Backlog into the active sprint workflow only after their granularity and feasibility were validated.
* **Small Items:** User Stories were decomposed into smaller, manageable technical tasks (e.g., separating the SQL schema creation from the API routing logic), facilitating efficient distribution among the subgroups.
* **Yesterday's Weather:** The 33-point capacity was calculated based on the team's historical performance (velocity from Sprint 0), preventing over-commitment and ensuring a sustainable pace.
* **Pigs Estimate:** Effort estimations were exclusively made by the "pigs"—the team members directly responsible for executing the technical tasks.
* **Definition of Ready (DoR) / Definition of Done (DoD):** An item was only considered "Done" when the real UI replaced the static Mocks and all automated acceptance tests passed without regressions.

---

## 4. Sprint Retrospective
**Date:** April 20, 2026

**Visual Evidence of the Scrumboard:**
*Below is the final status of our Kanban board after the conclusion of Sprint 1, demonstrating the flow of User Stories from the Product Backlog to the "Done" column, alongside the initial planning for Sprint 2.*

<img width="1930" height="1314" alt="image" src="https://github.com/user-attachments/assets/4165b364-ac83-44a6-ae7f-fc7d92c1636c" />


**Meeting Notes:**

* **Did Well (things we should continue):**
    * **Cross-Stack Integration:** The strict separation of concerns in the backend (`main.py` for routing vs. `database.py` for SQL) allowed for clean integration with the frontend via the `http` package.
    * **Testing Rigor:** Overcoming technical challenges in UI testing (such as transitioning from `ListView` to `Scrollable` finders and resolving `RenderFlex` overflows using `Expanded` widgets) heavily reinforced code robustness.

* **Do Differently (areas for improvement):**
    * **Cache and Naming Management:** Case-sensitivity conflicts between macOS and Git caused significant delays during test execution due to IDE "ghost files".
    * *How:* We will enforce a strict `snake_case` (all lowercase) naming convention from the exact moment a file is created. If a rename is needed, we will strictly use `git mv` via terminal rather than IDE shortcuts to prevent OS-level cache discrepancies.

* **Puzzles (things we don’t know yet if they are right or wrong):**
    * **Matching Algorithms:** We are debating whether the current `destination_norm` strict matching is sufficient or if *fuzzy matching* logic should be implemented to handle spelling variations in user destination searches.
    * **Dependency Injection Strategy:** We are currently evaluating the best architectural approach to inject the API client into our Flutter widgets to facilitate seamless mocking in future tests.

---
