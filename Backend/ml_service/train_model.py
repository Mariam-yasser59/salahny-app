from pathlib import Path

import joblib
import numpy as np
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

FAULT_PROFILES = {
    'Healthy': {
        'COOLANT_TEMPERATURE': (82, 96),
        'ENGINE_RPM': (750, 2400),
        'VEHICLE_SPEED': (0, 110),
        'CONTROL_MODULE_VOLTAGE': (12.6, 14.4),
        'ENGINE_LOAD': (18, 55),
        'THROTTLE': (8, 38),
        'SHORT_TERM_FUEL_TRIM_BANK_1': (-5, 5),
        'LONG_TERM_FUEL_TRIM_BANK_1': (-5, 5),
        'FUEL_AIR_COMMANDED_EQUIV_RATIO': (0.98, 1.02),
        'CATALYST_TEMPERATURE_BANK1_SENSOR1': (400, 650),
        'CATALYST_TEMPERATURE_BANK1_SENSOR2': (380, 630),
        'INTAKE_AIR_TEMP': (20, 45),
        'TIMING_ADVANCE': (8, 20),
    },
    'Engine Overheating': {
        'COOLANT_TEMPERATURE': (106, 126),
        'ENGINE_RPM': (1200, 4200),
        'VEHICLE_SPEED': (0, 90),
        'CONTROL_MODULE_VOLTAGE': (12.2, 14.2),
        'ENGINE_LOAD': (45, 90),
        'THROTTLE': (18, 58),
        'SHORT_TERM_FUEL_TRIM_BANK_1': (-3, 6),
        'LONG_TERM_FUEL_TRIM_BANK_1': (-3, 6),
        'FUEL_AIR_COMMANDED_EQUIV_RATIO': (0.97, 1.05),
        'CATALYST_TEMPERATURE_BANK1_SENSOR1': (600, 900),
        'CATALYST_TEMPERATURE_BANK1_SENSOR2': (580, 880),
        'INTAKE_AIR_TEMP': (40, 70),
        'TIMING_ADVANCE': (5, 18),
    },
    'Alternator Failure': {
        'COOLANT_TEMPERATURE': (80, 104),
        'ENGINE_RPM': (850, 3300),
        'VEHICLE_SPEED': (0, 100),
        'CONTROL_MODULE_VOLTAGE': (10.6, 12.0),
        'ENGINE_LOAD': (20, 65),
        'THROTTLE': (10, 45),
        'SHORT_TERM_FUEL_TRIM_BANK_1': (-4, 4),
        'LONG_TERM_FUEL_TRIM_BANK_1': (-4, 4),
        'FUEL_AIR_COMMANDED_EQUIV_RATIO': (0.98, 1.02),
        'CATALYST_TEMPERATURE_BANK1_SENSOR1': (350, 600),
        'CATALYST_TEMPERATURE_BANK1_SENSOR2': (330, 580),
        'INTAKE_AIR_TEMP': (20, 50),
        'TIMING_ADVANCE': (8, 18),
    },
    'Throttle Body Fault': {
        'COOLANT_TEMPERATURE': (82, 104),
        'ENGINE_RPM': (2500, 5200),
        'VEHICLE_SPEED': (0, 35),
        'CONTROL_MODULE_VOLTAGE': (12.2, 14.1),
        'ENGINE_LOAD': (35, 82),
        'THROTTLE': (55, 96),
        'SHORT_TERM_FUEL_TRIM_BANK_1': (-6, 6),
        'LONG_TERM_FUEL_TRIM_BANK_1': (-6, 6),
        'FUEL_AIR_COMMANDED_EQUIV_RATIO': (0.96, 1.04),
        'CATALYST_TEMPERATURE_BANK1_SENSOR1': (450, 750),
        'CATALYST_TEMPERATURE_BANK1_SENSOR2': (430, 730),
        'INTAKE_AIR_TEMP': (25, 55),
        'TIMING_ADVANCE': (6, 20),
    },
    'Transmission Slip': {
        'COOLANT_TEMPERATURE': (88, 108),
        'ENGINE_RPM': (3500, 5600),
        'VEHICLE_SPEED': (5, 45),
        'CONTROL_MODULE_VOLTAGE': (12.2, 14.2),
        'ENGINE_LOAD': (50, 94),
        'THROTTLE': (35, 78),
        'SHORT_TERM_FUEL_TRIM_BANK_1': (-4, 5),
        'LONG_TERM_FUEL_TRIM_BANK_1': (-4, 5),
        'FUEL_AIR_COMMANDED_EQUIV_RATIO': (0.97, 1.03),
        'CATALYST_TEMPERATURE_BANK1_SENSOR1': (500, 800),
        'CATALYST_TEMPERATURE_BANK1_SENSOR2': (480, 780),
        'INTAKE_AIR_TEMP': (30, 60),
        'TIMING_ADVANCE': (5, 16),
    },
    'O2 Sensor Failure': {
        # Key signals: very high fuel trims (ECU compensating for faulty O2 reading),
        # lean lambda, lower catalyst temp differential
        'COOLANT_TEMPERATURE': (75, 100),
        'ENGINE_RPM': (750, 3000),
        'VEHICLE_SPEED': (0, 100),
        'CONTROL_MODULE_VOLTAGE': (12.6, 14.4),
        'ENGINE_LOAD': (20, 60),
        'THROTTLE': (8, 40),
        'SHORT_TERM_FUEL_TRIM_BANK_1': (18, 40),
        'LONG_TERM_FUEL_TRIM_BANK_1': (10, 25),
        'FUEL_AIR_COMMANDED_EQUIV_RATIO': (0.82, 0.93),
        'CATALYST_TEMPERATURE_BANK1_SENSOR1': (450, 650),
        'CATALYST_TEMPERATURE_BANK1_SENSOR2': (250, 400),
        'INTAKE_AIR_TEMP': (20, 50),
        'TIMING_ADVANCE': (4, 14),
    },
    'Thermostat Stuck Open': {
        # Key signals: coolant never reaches operating temp, long run time, timing retarded
        'COOLANT_TEMPERATURE': (40, 75),
        'ENGINE_RPM': (700, 2500),
        'VEHICLE_SPEED': (0, 120),
        'CONTROL_MODULE_VOLTAGE': (12.6, 14.4),
        'ENGINE_LOAD': (15, 50),
        'THROTTLE': (8, 35),
        'SHORT_TERM_FUEL_TRIM_BANK_1': (5, 18),
        'LONG_TERM_FUEL_TRIM_BANK_1': (5, 15),
        'FUEL_AIR_COMMANDED_EQUIV_RATIO': (0.94, 1.02),
        'CATALYST_TEMPERATURE_BANK1_SENSOR1': (200, 420),
        'CATALYST_TEMPERATURE_BANK1_SENSOR2': (180, 400),
        'INTAKE_AIR_TEMP': (15, 40),
        'TIMING_ADVANCE': (2, 12),
    },
}


def _rand(rng, low, high, rows):
    return rng.uniform(low, high, rows)


def build_demo_dataset(rows_per_class=300):
    rng = np.random.default_rng(42)
    rows = []
    for label, profile in FAULT_PROFILES.items():
        for _ in range(rows_per_class):
            # Start with neutral baseline values for non-profiled features
            throttle_val = profile.get('THROTTLE', (8, 38))
            row = {
                'CAR_ID': f'demo_{label.lower().replace(" ", "_")}_{len(rows)}',
                TARGET: label,
                'ENGINE_RUN_TIME': rng.integers(60, 7200),
                'INTAKE_MANIFOLD_PRESSURE': rng.uniform(25, 95),
                'FUEL_TANK': rng.uniform(10, 100),
                'ABSOLUTE_THROTTLE_B': _rand(rng, throttle_val[0], throttle_val[1], 1)[0],
                'PEDAL_D': _rand(rng, throttle_val[0] * 0.8, throttle_val[1] * 0.9, 1)[0],
                'PEDAL_E': _rand(rng, throttle_val[0] * 0.8, throttle_val[1] * 0.9, 1)[0],
                'COMMANDED_THROTTLE_ACTUATOR': _rand(rng, throttle_val[0], throttle_val[1], 1)[0],
                'RELATIVE_THROTTLE_POSITION': _rand(rng, throttle_val[0] * 0.5, throttle_val[1] * 0.8, 1)[0],
                'ABSOLUTE_BAROMETRIC_PRESSURE': rng.uniform(94, 103),
                'COMMANDED_EVAPORATIVE_PURGE': rng.uniform(0, 100),
            }
            # Apply all profiled features (overrides defaults above if overlap)
            for feature, (low, high) in profile.items():
                row[feature] = _rand(rng, low, high, 1)[0]
            rows.append(row)
    return pd.DataFrame(rows)


def main():
    if not DATASET_PATH.exists():
        AI_DIR.mkdir(parents=True, exist_ok=True)
        demo = build_demo_dataset()
        demo.to_csv(DATASET_PATH, index=False)
        print(f'Dataset not found, generated demo dataset at {DATASET_PATH}')

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
        n_jobs=1,
        random_state=42,
    )
    model.fit(x_train, y_train)

    joblib.dump(model, MODEL_PATH)
    joblib.dump(encoder, ENCODER_PATH)

    print(f'Model saved to {MODEL_PATH}')
    print(f'Encoder saved to {ENCODER_PATH}')


if __name__ == '__main__':
    main()
