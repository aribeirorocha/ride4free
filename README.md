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
Our requirements are documented as **User Stories** in our [GitHub Project T4-Scrumboard](LINK_DO_TEU_PROJETO). We followed the **INVEST** guidelines to ensure each story is Independent, Negotiable, Valuable, Estimable, Small, and Testable.

| ID | Title | Priority (MoSCoW) | Effort (Fibonacci) | Status |
| :--- | :--- | :--- | :--- | :--- |
| #30 | [US1: Publish Solidarity Ride](https://github.com/LEIC-ES-2025-26-2LEIC05/issues/30) | **Must-have** | 8 | Ready |
| #31 | [US2: Book Ride Seat](https://github.com/LEIC-ES-2025-26-2LEIC05/issues/32) | **Must-have** | 5 | Ready |
| #33 | [US3: Search with Walking Tolerance](https://github.com/LEIC-ES-2025-26-2LEIC05/issues/33) | **Should-have** | 3 | Ready |
| #32 | [US4: Rate Passenger Conduct](https://github.com/LEIC-ES-2025-26-2LEIC05/issues/34) | **Could-have** | 3 | Ready |

---

### Requirements Quality (DoR)

Each User Story in our backlog includes:
* **Gherkin Scenarios:** Clear "Given/When/Then" acceptance tests to confirm requirements are met.
* **User Interface Mockups:** High-fidelity drafts attached to each issue to guide frontend development.
* **Estimation:** Value (Business Priority) and Effort (Story Points) defined by the whole team.
* **Refinement:** Larger stories were broken down into technical **Tasks** to be "immediately actionable" as per the [LEIC-ES Dashboard criteria]().

> **Note:** All AI-assisted drafting (Gherkin/Tasks) is transparently labeled with `MisterAI`.
> 
### Domain model

<!-- 
To better understand the context of the software system, it is useful to have a simple UML class diagram with all and only the key concepts (names, attributes) and relationships involved of the problem domain addressed by your app. 
Also provide a short textual description of each concept (domain class). 

Example:
 <p align="center" justify="center">
  <img src="https://github.com/FEUP-LEIC-ES-2022-23/templates/blob/main/images/DomainModel.png"/>
</p>
-->


## Architecture and Design
<!--
The architecture of a software system encompasses the set of key decisions about its organization. 

A well written architecture document is brief and reduces the amount of time it takes new programmers to a project to understand the code to feel able to make modifications and enhancements.

To document the architecture requires describing the decomposition of the system in their parts (high-level components) and the key behaviors and collaborations between them. 

In this section you should start by briefly describing the components of the project and their interrelations. You should describe how you solved typical problems you may have encountered, pointing to well-known architectural and design patterns, if applicable.
-->


### Logical architecture
<!--
The purpose of this subsection is to document the high-level logical structure of the code (Logical View), using a UML diagram with logical packages, without the worry of allocating to components, processes or machines.

It can be beneficial to present the system in a horizontal decomposition, defining layers and implementation concepts, such as the user interface, business logic and concepts.

Example of _UML package diagram_ showing a _logical view_ of the Eletronic Ticketing System (to be accompanied by a short description of each package):

![LogicalView](https://user-images.githubusercontent.com/9655877/160585416-b1278ad7-18d7-463c-b8c6-afa4f7ac7639.png)
-->


### Physical architecture
<!--
The goal of this subsection is to document the high-level physical structure of the software system (machines, connections, software components installed, and their dependencies) using UML deployment diagrams (Deployment View) or component diagrams (Implementation View), separate or integrated, showing the physical structure of the system.

It should describe also the technologies considered and justify the selections made. Examples of technologies relevant for ESOF are, for example, frameworks for mobile applications (such as Flutter).

Example of _UML deployment diagram_ showing a _deployment view_ of the Eletronic Ticketing System (please notice that, instead of software components, one should represent their physical/executable manifestations for deployment, called artifacts in UML; the diagram should be accompanied by a short description of each node and artifact):

![DeploymentView](https://user-images.githubusercontent.com/9655877/160592491-20e85af9-0758-4e1e-a704-0db1be3ee65d.png)
-->


### Functional prototype
<!--
To help on validating all the architectural, design and technological decisions made, we usually implement a functional prototype, a thin vertical slice of the system integrating as much technologies as we can.

In this subsection please describe which feature, or part of it, you have implemented, and how, together with a snapshot of the user interface, if applicable.

At this phase, instead of a complete user story, you can simply implement a small part of a feature that demonstrates thay you can use the technology, for example, show a screen with the app credits (name and authors).
-->

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

### Sprint 0

### Sprint 1

### Sprint 2

### Sprint 3

### Sprint 4

### Final Release

[your product name] Development Report

Welcome to the documentation of [your product name]!

This Software Development Report, tailored for LEIC-ES-2025-26, provides comprehensive details about [your product name], starting from an high-level vision and going into low-level implementation decisions.

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
    team member Tomás Gonçalves and up202208997@up.pt

Business Modelling

Business modeling in software development involves defining the product's vision, understanding market needs, aligning features with user expectations, and setting the groundwork for strategic planning and execution.
Product Vision
Features and Assumptions
Requirements
User Stories
Domain model
Architecture and Design
Logical architecture
Physical architecture
Functional prototype
Project management
Sprint 0
Sprint 1
Sprint 2
Sprint 3
Sprint 4
Final Release
=======
>>>>>>> Stashed changes
