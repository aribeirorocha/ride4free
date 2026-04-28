<<<<<<< Updated upstream
<!-- Template file for README.md for LEIC-ES-2025-26 -->

> [!NOTE] In this file, you will find the structure you should follow to document your mobile app in the README.md file for LEIC-ES-2025-26. It is a single file with guidelines. You can add more sections, but for assessment reasons and automation, please make sure to include all sections of this template. Your professors will clarify about specificities of your app.

# Ride4Free Development Report

Welcome to the documentation of **Ride4Free**!

This Software Development Report, tailored for LEIC-ES-2025-26, provides comprehensive details about **Ride4Free**, starting from an high-level vision and going into low-level implementation decisions. 

It is organised by the following activities: 

* [Business modeling](#Business-Modelling) 
  * [Product Vision](#Product-Vision)
  * [Features and Assumptions](#Features-and-Assumptions)
* [Requirements](#Requirements)
  * [User stories](#User-stories)
  * [Domain model](#Domain-model)
  * [User interfaces](#User-interfaces)
* [Architecture and Design](#Architecture-And-Design)
  * [Logical architecture](#Logical-Architecture)
  * [Physical architecture](#Physical-Architecture)
  * [Functional prototype](#Functional-Prototype)
* [Project management](#Project-Management)
  * [Sprint 0](#Sprint-0)
  * [Sprint 1](#Sprint-1)
  * [Sprint 2](#Sprint-2)
  * [Sprint 3](#Sprint-3)
  * [Final Release](#Final-Release)

Contributions are expected to be made exclusively by the initial team, but we may open them to the community, after the course, in all areas and topics: requirements, technologies, development, experimentation, testing, etc.

Please contact us!

Thank you!

* Thomas Tuerlinckx and up202403993@up.pt
* Filipe Silva and up202409216@up.pt
*  Pedro Dinis and up202205947@up.pt
* André Rocha and up202407636@up.pt
* Tomás Gonçalves and up202208997@up.pt

---
## Business Modelling

The app we propose, Ride4Free, has the objective to reduce the usage of cars. The intense use of cars, is a leading cause in pollution. However, one way of limiting that, is through the reduce utilization of half empty cars. That achieve with lifts. That way, if 5 people want to get to point B, instead of needing 5 cars, they might only use 1. 

The biggest issue with that, is that the people might not know each other, making it difficult to find people to share the ride. That's where our app steps in. We can connect people, and allow them to benefit from lifts, making it a great way to avoid excessive usage of cars, get free rides and save the planet. 

But the person riding their car might find it disadvantageous to waste gas, or have stranger in his car. That's where we implement  

Business modeling in software development involves defining the product's vision, understanding market needs, aligning features with user expectations, and setting the groundwork for strategic planning and execution.

### Product Vision




**Ride4Free – Full Product Vision**

The app **Ride4Free** aims to transform the way people move by reducing unnecessary car usage and promoting sustainable transportation. Today, many cars on the road are underutilized, often carrying only one person while contributing to traffic congestion, high fuel consumption, and pollution. Ride4Free addresses this by connecting drivers who have empty seats with passengers traveling the same route, creating an efficient, eco-friendly way to share rides.

For passengers, Ride4Free provides **free rides**, reducing transportation expenses and giving easy access to travel without owning a car. For drivers, the app ensures safety through **verified profiles, reviews, and secure ride matching**. Finally, by implementing a point system and a leader, we are using basic human psychology to encourage the competition and therefore the usage of the app. By making ride-sharing easy, safe, and rewarding, Ride4Free encourages more people to choose shared rides over solo car trips.

Our vision is to create a **community-driven ecosystem** where convenience meets sustainability: fewer cars on the road, lower emissions, more cost-effective travel, and the opportunity to connect with new people. Ultimately, Ride4Free doesn’t just move people—it moves society closer to a greener, smarter, and more connected future.

**Key Features Driving This Vision:**

- Smart route matching to minimize detours for drivers.
   
- Verified profiles, ratings, and ride history for safety and trust.
   
"- Automatic cost-sharing for fuel to reward drivers fairly."
   
- Real-time ride availability and notifications for convenience.

- Community-building features, such as messaging and shared trips, to foster trust and engagement.
- A point system that encourages app utilization. 
<!-- 
Start by defining a clear and concise product vision for your app, to help members of the team, contributors, and users into focusing their often disparate views into a concise, visual, and short textual form. 

The vision should provide a "high concept" of the product for marketers, developers, and managers.

A product vision describes the essential of the product and sets the direction to where a product is headed, and what the product will deliver in the future. 

**We favor a catchy and concise statement, ideally one sentence.**

We suggest you use the product vision template described in the following link:
* [How To Create A Convincing Product Vision To Guide Your Team, by uxstudioteam.com](https://uxstudioteam.com/ux-blog/product-vision/)

To learn more about how to write a good product vision, please read:
* [Vision, by scrumbook.org](http://scrumbook.org/value-stream/vision.html)
* [Product Management: Product Vision, by ProductPlan](https://www.productplan.com/glossary/product-vision/)
* [20 Inspiring Vision Statement Examples (2019 Updated), by lifehack.org](https://www.lifehack.org/articles/work/20-sample-vision-statement-for-the-new-startup.html)
-->


### Features and Assumptions

- Dynamic Maps: depending on the profile of the user (rider of passenger), the map gps chooses the best route to both go to the destination in the fastest way possible, and get as many people as possible there. 

- Login system: Basic login to keep track of the users.

- Point system: The points allow for competitive and buy cosmetic for the profile 
<!-- 
Indicate an  initial/tentative list of high-level features - high-level capabilities or desired services of the system that are necessary to deliver benefits to the users.
 - Feature XPTO - a few words to briefly describe the feature
 - Feature ABCD - ...
...

Optionally, indicate an initial/tentative list of assumptions that you are doing about the app and dependencies of the app to other systems.
-->

## Requirements

### User Stories
Our requirements are documented as **User Stories** in our [GitHub Project T4-Scrumboard](https://github.com/orgs/LEIC-ES-2025-26-2LEIC05/projects/16). We followed the **INVEST** guidelines to ensure each story is Independent, Negotiable, Valuable, Estimable, Small, and Testable.

| ID | Title | Priority (MoSCoW) | Effort (Fibonacci) | Status |
| :--- | :--- | :--- | :--- | :--- |
| #30 | [US1: Publish Solidarity Ride](https://github.com/LEIC-ES-2025-26-2LEIC05/T4/issues/30) | **Must-have** | 21 | In-Progress |
| #31 | [US2: Book Ride Seat](https://github.com/LEIC-ES-2025-26-2LEIC05/T4/issues/32) | **Must-have** | 13 | In-Progress |
| #33 | [US3: Search with Walking Tolerance](https://github.com/LEIC-ES-2025-26-2LEIC05/T4/issues/33) | **Should-have** | 8 | In-Progress |
| #32 | [US4: Rate Passenger Conduct](https://github.com/LEIC-ES-2025-26-2LEIC05/T4/issues/34) | **Could-have** | 13 | In-Progress |

---

### Requirements Quality (DoR)

Each User Story in our backlog includes:
* **Gherkin Scenarios:** Clear "Given/When/Then" acceptance tests to confirm requirements are met.
* **User Interface Mockups:** High-fidelity drafts attached to each issue to guide frontend development.
* **Estimation:** Value (Business Priority) and Effort (Story Points) defined by the whole team.
* **Refinement:** Larger stories were broken down into technical **Tasks** to be "immediately actionable" as per the LEIC-ES Dashboard criteria.

> **Note:** All AI-assisted drafting (Gherkin/Tasks) is transparently labeled with `MisterAI`.

### Domain model

Our app allows *Users* to create personal accounts, enabling them to create *Trajects* or *Reservations*. It includes different types of users, such as *Drivers* and *Passengers*, and supports interactions between them.

User - store information about user with his statistics (id, name, email, password, points).
Driver - represents a user that can create trajects.
Passenger - represents a user that can make reservations.
Traject - store information about a traject, including origin, destination, timeDeparture, availableSeats and km.
Reservation - store information about a reservation, including its state (accepted, rejected, ...), and is associated with a traject.
Avaliation - stores the pontuation (score) related to users.
LeaderBoard - ranks each user by the amount of pontuation.

<img width="704" height="702" alt="image" src="https://github.com/user-attachments/assets/ca1222c3-9a21-4c64-ae14-2709ac074d9a" />



## Architecture and Design



### Logical architecture
User interacts through the *User Interface* for visual elements and interactions, with the *Business Logic* layer handling core functionalities, and theexternal services, specifically OpenStreetMap, which is used for map-related features. Data storage and retrieval are handled by the DataBase, through the Ride4Free database schema.

<img width="1003" height="683" alt="image" src="https://github.com/user-attachments/assets/24708942-9c61-4d71-96d1-dd4e0f26b263" />


### Physical architecture

Each user interacts with the application via their mobile device. The application accesses external machines to retrieve necessary data, such as the OpenStreetMap and the DataBase.

<img width="683" height="443" alt="image" src="https://github.com/user-attachments/assets/3d6a97bf-2373-4171-a795-3d28957a6d7c" />

---

### Functional prototype

To validate our architectural and technological decisions early in the development process, we implemented a functional prototype focusing on two critical pillars of the **Ride4Free** experience: geospatial interaction and community trust.

#### 1. Interactive Map Integration
We successfully integrated a dynamic, fully interactive map view into the application. In this prototype, the user can open the map screen, pan across different areas, and zoom in/out smoothly to visualize ride locations.

* **Implementation:** Developed using the `flutter_map` package. Tiles are fetched in real-time from an external provider (CartoDB / OpenStreetMap) using a custom dark-themed layer (`dark_all`).
* **Validation:** Proved that the physical architecture correctly handles external API communication and that Flutter manages complex, gesture-based UI components with high performance.

#### 2. Profile Rating & Community Evaluation
We implemented an interactive rating system that allows users to evaluate their experience with recent drivers or passengers, fostering a self-regulated and safe community.

* **Implementation:** Built as a custom `StatefulWidget` (ProfileRatingButton) that triggers a bottom-sheet interface. It features a custom star-picker component and local state management to handle real-time UI updates when a user assigns a score (1-5 stars).
* **Validation:** Demonstrated our ability to build reusable UI components and manage interactive states, ensuring that user feedback is captured and reflected instantly in the interface.


**Technical Assumptions Validated:**
1.  **Frontend Versatility:** Flutter efficiently handles both heavy graphical tasks (Maps) and complex interactive forms (Ratings).
2.  **State Management:** The prototype confirms that the chosen state management approach is sufficient for handling real-time user interactions.
3.  **External Connectivity:** Validated the app's capability to integrate with third-party geospatial services.

Below is a snapshot of the functional prototype in action:

<img width="200" height="450" alt="Interactive Map Prototype" src="https://github.com/user-attachments/assets/e3f69d53-4b98-4153-baf1-02279a926f8c" />

## Project management
<!--
Software project management is the art and science of planning and leading software projects, in which they are planned, implemented, monitored and controlled.

In the context of ESOF, we recommend each team to adopt a set of project management practices and tools capable of registering tasks, assigning tasks to team members, adding estimations to tasks, monitor tasks progress, and therefore being able to track their projects.

Common practices of managing agile software development with Scrum are: backlog management, release management, estimation, Sprint planning, Sprint development, acceptance tests, and Sprint retrospectives.

You can find below information and references related with the project management: 

* Backlog management: Product backlog and Sprint backlog in a [Github Projects board](https://github.com/orgs/FEUP-LEIC-ES-2023-24/projects/64);
* Release management: [v0](#), v1, v2, v3, ...;
* Sprint planning and retrospectives: 
  * plans: screenshots of Github Projects board at begin and end of each Sprint;
  * retrospectives: meeting notes in a document in the repository, addressing the following questions:
    * Did well: things we did well and should continue;
    * Do differently: things we should do differently and how;
    * Puzzles: things we don’t know yet if they are right or wrong;
    * list of a few improvements to implement next Sprint;

-->
To ensure a smooth, transparent, and iterative development process for **Ride4Free**, our team adopted Agile methodologies, specifically focusing on the **Scrum** framework. We utilize a set of practices and tools to plan, implement, monitor, and control our software project effectively.

Our project management workflow is structured around the following key areas:

* **Backlog Management:** We manage both our Product Backlog and Sprint Backlogs using our [GitHub Projects board](https://github.com/orgs/LEIC-ES-2025-26-2LEIC05/projects/16). This board acts as our single source of truth for tracking User Stories, Tasks, effort estimations (Fibonacci sequence), and priorities (MoSCoW method).
* **Release Management:** We align our releases with the end of our Sprints. Code increments are systematically tagged (e.g., `v0` for Sprint 0, `v1` for Sprint 1) in our GitHub repository to mark stable milestones and evaluate progress.
* **Sprint Planning & Retrospectives:** * **Plans:** At the beginning of each Sprint, we hold a planning meeting to select User Stories from the Product Backlog, break them down into actionable tasks, and move them to the Sprint Backlog. Visual evidence of our Agile workflow is documented through screenshots of the board at the beginning and end of each Sprint.
  * **Retrospectives:** At the end of every Sprint, the team conducts a retrospective meeting to inspect our workflow and adapt our processes. The detailed meeting notes (addressing what we did well, what to do differently, open puzzles, and future improvements) are documented in our repository.

---

### Sprint 0
The detailed notes from our Sprint 0 Planning and Retrospective (including what we did well, what to do differently, and puzzles) can be found in our dedicated [SprintPlanningRetrospectives.md](https://github.com/LEIC-ES-2025-26-2LEIC05/T4/blob/main/SprintPlanningRetrospectives.md).

### Sprint 1
The detailed notes from our Sprint 1 Review, Planning, and Retrospective (including the Agile Patterns applied, achievements, team structure, and future improvements) can be found in our dedicated [SprintPlanningRetrospectives.md](https://github.com/LEIC-ES-2025-26-2LEIC05/T4/blob/main/Sprint1PlanningRetrospectives.md).

### Sprint 2

### Sprint 3

### Sprint 4

### Final Release

Ride4Free Development Report

Welcome to the documentation of Ride4Free!

This Software Development Report, tailored for LEIC-ES-2025-26, provides comprehensive details about Ride4Free, starting from an high-level vision and going into low-level implementation decisions.

It is organised by the following activities:

    Business modeling
        Product Vision
        Features and Assumptions
    Requirements
        User stories
        Domain model
        User interfaces
    Architecture and Design
        Logical architecture
        Physical architecture
        Functional prototype
    Project management
        Sprint 0
        Sprint 1
        Sprint 2
        Sprint 3
        Final Release

Contributions are expected to be made exclusively by the initial team, but we may open them to the community, after the course, in all areas and topics: requirements, technologies, development, experimentation, testing, etc.

Please contact us!

Thank you!!

    team member Thomas Tuerlinckx and up202403993@up.pt
    team member André Rocha and up202407636@up.pt
    team member name and email
    team member name and email
    team member Tomás Gonçalves and up202208997@up.pT
