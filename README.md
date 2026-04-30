# Salahny

Salahny is a Flutter application with a Node.js backend for drivers, workshops, and platform administration.

## Project Structure

- `lib/` Flutter mobile application
- `backend/` Node.js + Express + MongoDB API

## Backend Setup

Environment variables are already prepared in `backend/.env`:

```env
PORT=5000
MONGO_URI=mongodb://root:salahny123@ac-le6lfyd-shard-00-00.bdqkstd.mongodb.net:27017,ac-le6lfyd-shard-00-01.bdqkstd.mongodb.net:27017,ac-le6lfyd-shard-00-02.bdqkstd.mongodb.net:27017/salahnyDB?ssl=true&replicaSet=atlas-ho1vsx-shard-0&authSource=admin&retryWrites=true&w=majority&appName=salahny-cluster
JWT_SECRET=secret123
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

The Flutter app is still using local mock/state-driven data for many screens. The new backend gives you the real API foundation needed to replace those mocks with live database calls next.
