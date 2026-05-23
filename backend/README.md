# Ride4Free API

## Start server + public URL

```bash
cd backend
./start.sh
```

This starts the API and a Cloudflare quick tunnel, then **writes the URL** into `app_test/lib/app_config.dart`.

Restart the tunnel later? Run `./start.sh` again — the app config updates automatically.

## Change URL manually

Edit one line:

```dart
// app_test/lib/app_config.dart
static const String apiBaseUrl = 'https://your-url.trycloudflare.com';
```

Leave it empty (`''`) to use `localhost` / emulator while developing on your PC.

## Local only (no tunnel)

```bash
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```
