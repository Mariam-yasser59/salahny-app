# Salahny App — Integration Guide

## Architecture Overview

```
Flutter App (Mobile)
       │
       │  HTTP / REST (port 5000)
       ▼
Node.js + Express  ──── MongoDB Atlas
       │
       │  HTTP (port 5001)
       ▼
Python ML Service (FastAPI)
```

---

## 1. Backend Setup (Node.js)

### Requirements
- Node.js 18+
- A MongoDB Atlas account (connection string is already in `.env`)

### Steps

```bash
cd Backend

# 1. Install dependencies
npm install

# 2. The .env file is already created for you with the Atlas URI.
#    If you need to change it, edit Backend/.env

# 3. (Optional) Seed the database with sample data
node seed.js

# 4. Start the server
npm run dev      # development (auto-reload)
# or
npm start        # production
```

The API will be available at: **http://localhost:5000/api**

Health check: http://localhost:5000/api/health

---

## 2. ML Service Setup (Python / FastAPI)

The ML service handles OBD2 diagnostic predictions.

### Requirements
- Python 3.9+
- pip

### Steps

```bash
cd Backend/ml_service

# 1. Install dependencies
pip install -r requirements.txt

# 2. Train the model (first time only)
python train_model.py

# 3. Start the ML service
uvicorn app:app --host 0.0.0.0 --port 5001 --reload
```

The ML service will be available at: **http://localhost:5001**

> The Node.js backend calls this automatically during diagnostic scans.
> If it's not running, the backend falls back to pre-built diagnostic templates.

---

## 3. Flutter App Setup

### Requirements
- Flutter SDK 3.11+
- Android Studio / VS Code with Flutter plugin

### Steps

```bash
# From the project root
flutter pub get
flutter run
```

### Changing the Backend URL

The API URL is in `lib/core/constants/api_constants.dart`:

```dart
// Android emulator  →  http://10.0.2.2:5000/api   ✅ (default)
// iOS simulator     →  http://localhost:5000/api
// Real device       →  http://YOUR_LAPTOP_IP:5000/api
```

Change `baseUrl` to match your setup.

---

## 4. API Endpoints Reference

| Feature | Method | Endpoint |
|---|---|---|
| Register | POST | /api/auth/register |
| Login | POST | /api/auth/login |
| Get Profile | GET | /api/users/me |
| Get Vehicles | GET | /api/vehicles |
| Add Vehicle | POST | /api/vehicles |
| Update Vehicle | PUT | /api/vehicles/:id |
| Delete Vehicle | DELETE | /api/vehicles/:id |
| Get Workshops | GET | /api/workshops |
| Get Services | GET | /api/services |
| Get Packages | GET | /api/packages |
| Get Bookings | GET | /api/bookings |
| Create Booking | POST | /api/bookings |
| Update Booking Status | PATCH | /api/bookings/:id/status |
| Run Diagnostic Scan | POST | /api/diagnostics/scan |
| Get Diagnostic History | GET | /api/diagnostics |
| Get Notifications | GET | /api/notifications |
| Mark Notification Read | PATCH | /api/notifications/:id/read |
| Get Chat Messages | GET | /api/chat/bookings/:id/messages |
| Send Chat Message | POST | /api/chat/bookings/:id/messages |
| AI Chat | POST | /api/chat/ai |
| Purchase Package | POST | /api/payments/packages |
| Public Content | GET | /api/content/public-content |

---

## 5. Default Admin Account

The system auto-creates an admin account on first login attempt with:
- **Email:** admin@salahny.com  
- **Password:** Admin@123

---

## 6. Integration Status

| Module | Flutter Service | Backend Route | Status |
|---|---|---|---|
| Auth | `AuthService` | `/api/auth/*` | ✅ Connected |
| Vehicles | `VehicleService` | `/api/vehicles/*` | ✅ Connected |
| Bookings | `BookingService` | `/api/bookings/*` | ✅ Connected |
| Diagnostics | `DiagnosticsService` | `/api/diagnostics/*` | ✅ Connected |
| Chat | `ChatService` | `/api/chat/*` | ✅ Connected |
| Notifications | `NotificationService` | `/api/notifications/*` | ✅ Connected |
| Packages/Payment | `PackagePaymentService` | `/api/payments/*` | ✅ Connected |
| Services & Packages | `ServiceApi` | `/api/services`, `/api/packages` | ✅ Connected |
| Content | `ContentService` | `/api/content/*` | ✅ Connected |
| ML Diagnostics | via Node.js | ML service port 5001 | ✅ Connected (with fallback) |
