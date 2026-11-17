# Ride4Free — Carpooling Mobile App

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white) ![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white) ![SQLite](https://img.shields.io/badge/SQLite-003B57?logo=sqlite&logoColor=white) ![CI](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white) ![Grade](https://img.shields.io/badge/Grade-19.8%2F20-brightgreen)

**Ride4Free** connects drivers who have empty seats with people heading the same way. The goal is fewer half-empty cars on the road, lower travel costs and less pollution.

> Project for **Software Engineering (ES)** — BSc in Informatics and Computing Engineering (L.EIC), FEUP, 2025/2026. **Final grade: 19.8/20.**

<p align="center"><img src="Design/sprint2.2.png" width="280" alt="Offer a ride screen"/></p>

## Features
- **Offer and find rides**, choosing departure and arrival points on a map (OpenStreetMap)
- **Verified profiles**, ratings and ride history for safety and trust
- **Points system** and a leaderboard that rewards drivers who share rides
- **In-app chat** and **notifications**
- University login, built for the FEUP community

## Architecture & stack
| Layer | Technology |
|---|---|
| Mobile app | **Flutter / Dart** |
| Backend API | **Python, FastAPI, Pydantic** |
| Database | **SQLite** |
| Maps | OpenStreetMap |
| Deployment | Backend exposed through **Cloudflare Tunnel**, for testing on real phones over 4G/5G |
| Quality | Unit and integration tests (Flutter + pytest), **CI with GitHub Actions** |

## Process
Developed with **Scrum** over **4 sprints**, each with planning, a review and a retrospective. The process included user stories, a domain model, mockups, user interviews and acceptance tests. Everything is documented in [`Docs/`](Docs) and in the [development report](DEVELOPMENT_REPORT.md).

## ▶ How to run
```bash
# Backend
cd backend && pip install -r requirements.txt
uvicorn main:app --reload --host 127.0.0.1 --port 8000

# App
cd Ride4Free && flutter pub get && flutter run
```

## My contribution
I was the **most active contributor** in the team:
- Main app screens and the app's integration with the API (`main.dart`, `ride4free_api.dart`)
- Backend endpoints (`backend/main.py`)
- **Unit and integration tests**, plus the test summary
- Sprint documentation, changelog and the final presentation

## Team
André Rocha · Thomas Tuerlinckx · Filipe Silva · Pedro Dinis
