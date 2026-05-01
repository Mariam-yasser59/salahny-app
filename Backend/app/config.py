from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    MONGODB_URL: str = "mongodb://localhost:27017"
    DATABASE_NAME: str = "salahny"
    JWT_SECRET: str = "change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    ML_MODEL_PATH: str = "../AI and ML/obd2_rf_model.pkl"
    ML_ENCODER_PATH: str = "../AI and ML/obd2_label_encoder.pkl"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
