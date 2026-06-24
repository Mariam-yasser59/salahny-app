# Salahny

Salahny is a Flutter application with a Node.js backend for drivers, workshops, and platform administration.

## Project Structure

- `lib/` Flutter mobile application
- `backend/` Node.js + Express + MongoDB API

## Backend Setup

Create `Backend/.env` from `Backend/.env.example` and put your real MongoDB password there. Do not commit the real password.

```env
PORT=5000
MONGO_URI=mongodb+srv://root:<db_password>@salahny-cluster.bdqkstd.mongodb.net/salahnyDB?retryWrites=true&w=majority&appName=salahny-cluster
JWT_SECRET=change_this_secret
ML_SERVICE_URL=http://127.0.0.1:5001
GOOGLE_CLIENT_ID=your-google-oauth-web-client-id
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

### Install and run

```bash
cd backend
npm install
npm run dev
```

### API Modules

- `config/` MongoDB connection
- `models/` Mongoose schemas
- `controllers/` route logic
- `routes/` API endpoints
- `middleware/` auth, roles, error handling
- `utils/` helpers

### Main API Endpoints

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/users/me`
- `GET /api/users`
- `POST /api/workshops`
- `GET /api/workshops`
- `POST /api/bookings`
- `PATCH /api/bookings/:id/status`

## Flutter

Set the backend URL per target:

```bash
flutter run --dart-define=SALAHNY_API_BASE_URL=https://salahny-backend-production.up.railway.app/api \
  --dart-define=SALAHNY_GOOGLE_CLIENT_ID=your-mobile-client-id \
  --dart-define=SALAHNY_GOOGLE_SERVER_CLIENT_ID=your-web-client-id
```

For Android Google Maps, provide `GOOGLE_MAPS_API_KEY` through `android/gradle.properties`
or the shell environment before building. For iOS, set the `GOOGLE_MAPS_API_KEY`
build setting so `Info.plist` can inject it at runtime. Railway also needs a public
`ML_SERVICE_URL` if production predictions should use the deployed ML service
instead of the backend fallback.
