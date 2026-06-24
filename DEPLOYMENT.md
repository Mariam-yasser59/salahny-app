# Salahny Public Deployment

This setup deploys:

- `salahny-backend`: public Node/Express API used by the Flutter app.
- `salahny-ai`: private Python/Flask ML service used only by the backend.
- MongoDB Atlas: existing cloud database.

The Flutter APK must point to the public backend URL, not a laptop IP.

## 1. Push Code

Push `main` to GitHub before creating the Render Blueprint.

## 2. Create Render Blueprint

1. Open Render Dashboard.
2. Choose New > Blueprint.
3. Connect `https://github.com/Mariam-yasser59/salahny-app`.
4. Select the repo root `render.yaml`.
5. When prompted, set `MONGO_URI` to the MongoDB Atlas connection string.

Render will create:

- private service: `salahny-ai`
- public web service: `salahny-backend`

## 3. MongoDB Atlas Network Access

Allow Render to reach Atlas. For quick testing, add this Network Access entry:

```text
0.0.0.0/0
```

For production, restrict access using a static outbound IP provider or a tighter network rule.

## 4. Verify Public Backend

After deploy finishes, open:

```text
https://YOUR-BACKEND.onrender.com/api/health
```

Expected response:

```json
{
  "success": true,
  "message": "Salahny API is running"
}
```

## 5. Rebuild APK For Any Phone

Replace the URL below with the Render backend URL:

```powershell
C:\flutter\bin\flutter.bat build apk --release --dart-define=SALAHNY_API_BASE_URL=https://YOUR-BACKEND.onrender.com/api
```

APK output:

```text
build\app\outputs\flutter-apk\app-release.apk
```

That APK can work on phones anywhere as long as the deployed backend, private AI service, and MongoDB Atlas are running.
