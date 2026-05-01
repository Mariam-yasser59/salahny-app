# Salahny Backend

Node.js API for authentication, workshops, bookings, and supporting app data.

## Setup

```bash
npm install
npm run dev
```

The server reads configuration from `.env`:

```env
PORT=5000
MONGO_URI=mongodb://root:salahny123@ac-le6lfyd-shard-00-00.bdqkstd.mongodb.net:27017,ac-le6lfyd-shard-00-01.bdqkstd.mongodb.net:27017,ac-le6lfyd-shard-00-02.bdqkstd.mongodb.net:27017/salahnyDB?ssl=true&replicaSet=atlas-ho1vsx-shard-0&authSource=admin&retryWrites=true&w=majority&appName=salahny-cluster
JWT_SECRET=secret123
```

When the database connection succeeds, the server prints:

```text
MongoDB Connected
```

## Main Routes

- `POST /auth/register`
- `POST /auth/login`
- `GET /users/profile`
- `GET /workshops`
- `POST /workshops`
- `POST /bookings`
- `PUT /bookings/:id/status`

The same API is also mounted under `/api`, which is what the Flutter app uses:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/users/me`
- `GET /api/workshops`
- `GET /api/services`
- `GET /api/packages`
- `POST /api/bookings`
- `POST /api/emergency`
- `POST /api/towing`
- `POST /api/car-wash`
- `POST /api/fuel-delivery`
- `POST /api/obd-prediction`
- `GET /api/chat/rooms`
- `GET /api/notifications`
- `POST /api/reviews`
- `GET /api/admin/dashboard`
- `POST /api/chat/ai`
- `GET /api/chat/bookings/:bookingId/messages`
- `POST /api/chat/bookings/:bookingId/messages`
- `POST /api/chat/bookings/:bookingId/share-diagnostic`
- `GET /api/content/public-content`
- `GET /api/content/admin/settings`
- `PUT /api/content/admin/settings`
- `PUT /api/content/admin/settings/password`
- `GET /api/diagnostics`
- `POST /api/diagnostics/scan`

## AI / ML Diagnostics Integration

The Node backend now bridges to the model assets in `AI and ML`.

1. Train the model artifacts into `AI and ML`:

```bash
cd Backend
python ml_service/train_model.py
```

This creates:

- `AI and ML/obd2_rf_model.pkl`
- `AI and ML/obd2_label_encoder.pkl`

2. Run the Python ML microservice:

```bash
cd Backend/ml_service
python app.py
```

It starts on `http://localhost:5001`.

3. Run the Node backend:

```bash
cd Backend
npm run dev
```

The diagnostics controller calls the ML service through `ML_SERVICE_URL` and falls back to seeded diagnostic templates if the service is unavailable. Default:

```env
ML_SERVICE_URL=http://127.0.0.1:5001
```

## Postman Quick Test

1. Register:

```json
{
  "name": "Test Driver",
  "email": "driver@test.com",
  "phone": "01012345678",
  "password": "Password1",
  "role": "driver"
}
```

2. Login:

```json
{
  "email": "driver@test.com",
  "password": "Password1"
}
```

Copy `accessToken`, then add this header to protected requests:

```text
Authorization: Bearer YOUR_TOKEN
```

3. Create workshop, using a workshop/admin token:

```json
{
  "name": "Fast Garage",
  "location": "Nasr City, Cairo",
  "services": ["Oil Change", "OBD Diagnostics"],
  "prices": { "Oil Change": 150, "OBD Diagnostics": 200 }
}
```

4. Create booking:

```json
{
  "workshop": "WORKSHOP_ID",
  "service": "Oil Change",
  "date": "2026-05-01T10:00:00.000Z",
  "time": "10:00",
  "vehicleInfo": "Toyota Corolla 2020",
  "notes": "Please check engine noise"
}
```

5. Update booking status:

```json
{
  "status": "accepted",
  "notes": "Workshop accepted the booking"
}
```

6. Emergency/towing/car wash/fuel examples:

```json
{ "location": "Cairo Festival City", "issue": "Car will not start", "phone": "01012345678" }
```

```json
{ "pickupLocation": "Maadi", "dropoffLocation": "Nasr City", "vehicleInfo": "Hyundai Elantra", "phone": "01012345678" }
```

```json
{ "location": "Heliopolis", "packageName": "Premium", "phone": "01012345678" }
```

```json
{ "location": "New Cairo", "fuelType": "gasoline", "liters": 10, "phone": "01012345678" }
```

## Flutter Notes

The app base URL lives in:

```text
lib/core/constants/api_constants.dart
```

Use:

- Android emulator: `http://10.0.2.2:5000/api`
- iOS simulator/desktop: `http://localhost:5000/api`
- Real phone: `http://YOUR_LAPTOP_IP:5000/api`

Troubleshooting:

- `EADDRINUSE`: port 5000 is already used. Stop the process or change `PORT`.
- `querySrv ECONNREFUSED`: DNS cannot resolve MongoDB Atlas. Use public DNS or a non-SRV Atlas URL.
- `401 No token provided`: add `Authorization: Bearer <token>`.
- Flutter cannot connect on emulator: use `10.0.2.2`, not `localhost`.
