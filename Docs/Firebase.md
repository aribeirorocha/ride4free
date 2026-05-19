# Firebase setup (Ride4Free)

Ride4Free can use **Firebase Authentication** so the app sends Firebase ID tokens to the API instead of local session tokens. Ride data still lives in SQLite on the backend until you move it to Firestore.

## 1. Create a Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/) and create a project (e.g. `ride4free`).
2. Enable **Authentication** → **Sign-in method** → **Email/Password**.

## 2. Configure Flutter (`flutterfire`)

From the repo root:

```bash
dart pub global activate flutterfire_cli
cd app_test
flutterfire configure
```

This generates `lib/firebase_options.dart` and `android/app/google-services.json`.

## 3. Enable Firebase in the app

In `app_test/lib/app_config.dart`:

```dart
static const bool useFirebaseAuth = true;
```

Rebuild the app (`flutter run` or your release script).

## 4. Configure the backend

1. In Firebase Console → **Project settings** → **Service accounts** → **Generate new private key**.
2. Save the JSON file outside the repo (e.g. `~/ride4free-firebase-adminsdk.json`).
3. Start the API with:

```bash
export FIREBASE_ENABLED=1
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/ride4free-firebase-adminsdk.json
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Or add those variables to `backend/start.sh` when you use the tunnel.

## 5. Verify

- Log in with university credentials (Sigarra) as usual.
- The app signs into Firebase with the same derived email/password and sends the Firebase ID token to the API.
- `GET /users/me` with `Authorization: Bearer <firebase-id-token>` should return your user.

## Local dev without Firebase

Leave `useFirebaseAuth = false` and do not set `FIREBASE_ENABLED`. The API keeps using SQLite session tokens from `/users/login` and `/users/register`.

## Next steps (optional)

- **Firestore**: replace `database.py` ride tables with Cloud Firestore collections.
- **Firebase Hosting**: host a static admin page or future web client.
- **FCM**: push notifications for new bookings.
