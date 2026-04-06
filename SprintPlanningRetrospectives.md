### Sprint 0 Retrospective
* **Sprint planning and retrospectives:** * 
**Date:** April 6, 2026
**Plans:** Visual evidence of our Agile workflow. Below are the snapshots of our Scrumboard.
    * ![Sprint 0 - Initial Backlog Creation]
    * <img width="2150" height="764" alt="image" src="https://github.com/user-attachments/assets/3cea9f9d-869c-4449-864b-a17ec01e564d" />

    
    * ![Sprint 0 - End of Sprint / Ready for Sprint 1]
    * 

Following the Agile Scrum framework, our team held a Sprint Retrospective meeting to inspect our workflow and adapt our processes for the upcoming sprint. Below are our meeting notes:

* **Did well (things we did well and should continue):**
  * **Backlog Organization:** We successfully set up the GitHub Projects board and wrote clear, INVEST-compliant User Stories (US1 to US4).
  * **Test-Driven Approach:** Implementing the Acceptance Test-Driven Development (ATDD) early on was a huge success. Creating the Flutter test skeletons with Mock Widgets guarantees that our code meets the Definition of Ready and Acceptance Criteria (Gherkin).
  * **Team Communication:** Effective distribution of tasks, ensuring everyone contributed to the architectural design and mockups.

* **Do differently (things we should do differently and how):**
  * **Environment Setup:** We lost some time dealing with local environment configurations (e.g., Flutter SDK paths not being recognized by the IDE). 
  * *How:* For the next sprints, we will dedicate the very first day to ensuring every team member's local environment is fully synchronized and properly configured before writing code.

* **Puzzles (things we don’t know yet if they are right or wrong):**
  * **Database Architecture:** We are still debating the best backend technology to handle the real-time ride matching and point system (e.g., using Firebase vs. building a custom REST API). We don't know yet which will integrate smoother with our Flutter frontend.
  * **State Management:** We need to decide if we will use Provider, Riverpod, or BLoC to manage the app's state as the app scales beyond the current Mock widgets.

* **List of a few improvements to implement next Sprint:**
  1. Ensure 100% of the team has their Flutter SDK and VS Code environments validated.
  2. Adopt a stricter policy for Git commit messages (no empty messages) to maintain a cleaner project history.
  3. Start replacing the Mock Widgets from Sprint 0 with the actual interactive UI elements for Sprint 1.
