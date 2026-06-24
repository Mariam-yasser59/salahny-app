# Salahny Backend

Node.js API for authentication, workshops, bookings, realtime chat/tracking, and supporting app data.

This repository now has one active backend runtime:

- `server.js` boots the Express app in `app.js`
- `ml_service/` is the separate Python ML microservice used only for predictions

## Setup

```bash
npm install
npm run dev
```

The server reads configuration from `.env`:

```env
PORT=5000
MONGO_URI=mongodb+srv://root:<db_password>@salahny-cluster.bdqkstd.mongodb.net/salahnyDB?retryWrites=true&w=majority&appName=salahny-cluster
JWT_SECRET=change_this_secret
JWT_REFRESH_SECRET=change_this_second_secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=30d
ML_SERVICE_URL=http://127.0.0.1:5001
PAYMENT_PROVIDER=simulated
STRIPE_SECRET_KEY=
GOOGLE_CLIENT_ID=
DOCUMENT_STORAGE_PROVIDER=mongodb
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

When the database connection succeeds, the server prints:

```text
MongoDB Connected
```

## Main Routes

- `POST /auth/register`
- `POST /auth/login`
- `GET /api/users/me`
- `PUT /api/users/me`
- `GET /api/users/me/vehicles`
- `POST /api/users/me/vehicles`
- `GET /workshops`
- `POST /workshops`
- `POST /bookings`
- `PATCH /api/bookings/:id/status`
- `GET /api/workshop-portal/services`
- `PUT /api/workshop-portal/services`

The same API is also mounted under `/api`, which is what the Flutter app uses:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
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
- `POST /api/payments/packages/intent`
- `POST /api/reviews`
- `GET /api/admin/dashboard`
- `POST /api/chat/ai`
- `GET /api/chat/bookings/:bookingId/messages`
- `POST /api/chat/bookings/:bookingId/messages`
- `POST /api/chat/bookings/:bookingId/share-diagnostic`
- `GET /api/tracking/:bookingId`
- `POST /api/tracking/:bookingId`
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

The diagnostics controller calls the ML service through `ML_SERVICE_URL`. If the service is unavailable, it still saves a dynamic rule-based report from the submitted OBD values; it does not use fixed diagnostic samples. Default:

```env
ML_SERVICE_URL=http://127.0.0.1:5001
```

## Realtime Transport

The Node server also exposes Socket.IO on the same host as the REST API.

- Booking chat emits `booking_message`
- Driver/admin chat emits `direct_message`
- Workshop/admin chat emits `workshop_admin_message`
- Live tracking emits `tracking_update`
- Notifications emit `notification_created`

Clients authenticate the socket with the same JWT used by REST, then join protected booking or workshop rooms. REST endpoints remain the source of truth, so Postman workflows stay unchanged while the app receives push updates immediately.

Workshop active jobs can start device GPS streaming from the Flutter app. The app posts location samples to the existing tracking endpoint and connected drivers receive them live over Socket.IO.

## Optional Production Providers

- Refresh tokens are rotated through `/api/auth/refresh`; access tokens stay short-lived.
- Package payments default to the existing simulated flow. Set `PAYMENT_PROVIDER=stripe` and `STRIPE_SECRET_KEY` to require a successful Stripe PaymentIntent before package activation.
- Verification documents default to MongoDB storage for local compatibility. Set `DOCUMENT_STORAGE_PROVIDER=cloudinary` and the `CLOUDINARY_*` variables to upload new files to Cloudinary instead while MongoDB keeps metadata.
- Google sign-in requires `GOOGLE_CLIENT_ID` on the backend plus Flutter build defines for `SALAHNY_GOOGLE_CLIENT_ID` and `SALAHNY_GOOGLE_SERVER_CLIENT_ID`.

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

Use `--dart-define=SALAHNY_API_BASE_URL=...` to point Flutter at the desired API host.

Troubleshooting:

- `EADDRINUSE`: port 5000 is already used. Stop the process or change `PORT`.
- `querySrv ECONNREFUSED`: DNS cannot resolve MongoDB Atlas. Use public DNS or a non-SRV Atlas URL.
- `401 No token provided`: add `Authorization: Bearer <token>`.
- Flutter cannot connect on emulator: use `10.0.2.2`, not `localhost`.
