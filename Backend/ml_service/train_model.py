from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder


ROOT = Path(__file__).resolve().parents[2]
AI_DIR = ROOT / 'AI and ML'
DATASET_PATH = AI_DIR / 'obd2_final_dataset.csv'
MODEL_PATH = AI_DIR / 'obd2_rf_model.pkl'
ENCODER_PATH = AI_DIR / 'obd2_label_encoder.pkl'

FEATURES = [
    'ENGINE_RUN_TIME',
    'ENGINE_RPM',
    'VEHICLE_SPEED',
    'THROTTLE',
    'ENGINE_LOAD',
    'COOLANT_TEMPERATURE',
    'LONG_TERM_FUEL_TRIM_BANK_1',
    'SHORT_TERM_FUEL_TRIM_BANK_1',
    'INTAKE_MANIFOLD_PRESSURE',
    'FUEL_TANK',
    'ABSOLUTE_THROTTLE_B',
    'PEDAL_D',
    'PEDAL_E',
    'COMMANDED_THROTTLE_ACTUATOR',
    'FUEL_AIR_COMMANDED_EQUIV_RATIO',
    'ABSOLUTE_BAROMETRIC_PRESSURE',
    'RELATIVE_THROTTLE_POSITION',
    'INTAKE_AIR_TEMP',
    'TIMING_ADVANCE',
    'CATALYST_TEMPERATURE_BANK1_SENSOR1',
    'CATALYST_TEMPERATURE_BANK1_SENSOR2',
    'CONTROL_MODULE_VOLTAGE',
    'COMMANDED_EVAPORATIVE_PURGE',
]
TARGET = 'FAILURE_TYPE'


def main():
    if not DATASET_PATH.exists():
        raise FileNotFoundError(f'Dataset not found: {DATASET_PATH}')

    df = pd.read_csv(DATASET_PATH)
    df = df.drop(columns=[column for column in ['CAR_ID'] if column in df.columns])

    x = df[FEATURES].fillna(df[FEATURES].median(numeric_only=True))
    y = df[TARGET].astype(str)

    encoder = LabelEncoder()
    y_encoded = encoder.fit_transform(y)

    x_train, _, y_train, _ = train_test_split(
        x,
        y_encoded,
        test_size=0.2,
        random_state=42,
        stratify=y_encoded,
    )

    model = RandomForestClassifier(
        n_estimators=200,
        max_features='sqrt',
        class_weight='balanced',
        n_jobs=-1,
        random_state=42,
    )
    model.fit(x_train, y_train)

    joblib.dump(model, MODEL_PATH)
    joblib.dump(encoder, ENCODER_PATH)

    print(f'Model saved to {MODEL_PATH}')
    print(f'Encoder saved to {ENCODER_PATH}')


if __name__ == '__main__':
    main()
