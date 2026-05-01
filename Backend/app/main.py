from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from .database import connect_db, close_db
from .config import settings
from .services import ml_service
from .routers import auth, users, vehicles, workshops, services, bookings, diagnostics, chat, notifications, packages


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    ml_service.load_model(settings.ML_MODEL_PATH, settings.ML_ENCODER_PATH)
    yield
    await close_db()


app = FastAPI(
    title="Salahny API",
    description="Backend for the Salahny automotive diagnostics & workshop booking app",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(vehicles.router)
app.include_router(workshops.router)
app.include_router(services.router)
app.include_router(bookings.router)
app.include_router(diagnostics.router)
app.include_router(chat.router)
app.include_router(notifications.router)
app.include_router(packages.router)


@app.get("/health", tags=["health"])
async def health():
    return {
        "status": "ok",
        "ml_model_loaded": ml_service.is_loaded(),
        "version": "1.0.0",
    }
