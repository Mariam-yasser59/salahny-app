# ═══════════════════════════════════════════════════════════════════════════════
#  OBD-II Vehicle Fault Detection — Random Forest Classifier
# ═══════════════════════════════════════════════════════════════════════════════

import pandas as pd
import numpy as np
import joblib
import json
import os
import sys
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import (
    accuracy_score, classification_report,
    confusion_matrix, ConfusionMatrixDisplay,
    f1_score, precision_score, recall_score,
    precision_recall_fscore_support,
)
from sklearn.preprocessing import LabelEncoder
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import warnings
warnings.filterwarnings('ignore')

# ── 1. Configuration ─────────────────────────────────────────────────────────

DATASET_PATH = '/Users/hosselgamed/Desktop/obd2_final_dataset.csv'

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

RF_PARAMS = {
    'n_estimators':      200,
    'max_depth':         None,
    'min_samples_split': 2,
    'min_samples_leaf':  1,
    'max_features':      'sqrt',
    'criterion':         'gini',
    'class_weight':      'balanced',
    'n_jobs':            -1,
    'random_state':      42,
}

TEST_SIZE   = 0.20
RANDOM_SEED = 42

MODEL_PATH   = 'obd2_rf_model.pkl'
ENCODER_PATH = 'obd2_label_encoder.pkl'


# ── 2. Helper: per-class metrics bar chart ────────────────────────────────────

def plot_per_class_metrics(y_true, y_pred, classes, title_suffix='', save_path=None):
    precision, recall, f1, _ = precision_recall_fscore_support(
        y_true, y_pred, labels=range(len(classes)), zero_division=0
    )

    x   = np.arange(len(classes))
    w   = 0.26
    fig, ax = plt.subplots(figsize=(max(10, len(classes) * 1.4), 6))

    ax.bar(x - w,   precision, w, label='Precision', color='#4C72B0', edgecolor='none')
    ax.bar(x,       recall,    w, label='Recall',    color='#DD8452', edgecolor='none')
    ax.bar(x + w,   f1,        w, label='F1-Score',  color='#55A868', edgecolor='none')

    ax.set_xticks(x)
    ax.set_xticklabels(classes, rotation=40, ha='right', fontsize=9)
    ax.set_ylim(0, 1.12)
    ax.yaxis.set_major_formatter(mticker.PercentFormatter(xmax=1))
    ax.set_ylabel('Score')
    ax.set_title(f'Per-class Precision / Recall / F1{title_suffix}', fontsize=13)
    ax.legend(loc='lower right')
    ax.spines[['top', 'right']].set_visible(False)

    for bars in ax.containers:
        ax.bar_label(bars, fmt='%.2f', fontsize=7, padding=2)

    plt.tight_layout()

    if save_path:
        plt.savefig(save_path, dpi=150)
        print(f'[PLOT] Per-class metrics saved → {save_path}')
    else:
        plt.show()

    return fig


# ── 3. Helper: print & return summary metrics ─────────────────────────────────

def print_metrics(y_true, y_pred, classes, label='Test set'):
    acc  = accuracy_score(y_true, y_pred)
    mac_f1   = f1_score(y_true, y_pred, average='macro',    zero_division=0)
    wgt_f1   = f1_score(y_true, y_pred, average='weighted', zero_division=0)
    mac_prec = precision_score(y_true, y_pred, average='macro',    zero_division=0)
    mac_rec  = recall_score(y_true, y_pred, average='macro',       zero_division=0)

    print(f'\n{"─"*60}')
    print(f'  Metrics — {label}')
    print(f'{"─"*60}')
    print(f'  Accuracy          : {acc:.4f}  ({acc*100:.2f}%)')
    print(f'  Macro Precision   : {mac_prec:.4f}')
    print(f'  Macro Recall      : {mac_rec:.4f}')
    print(f'  Macro F1-Score    : {mac_f1:.4f}')
    print(f'  Weighted F1-Score : {wgt_f1:.4f}')
    print(f'{"─"*60}')
    print(classification_report(y_true, y_pred, target_names=classes, zero_division=0))

    return {
        'accuracy': float(acc),
        'macro_precision': float(mac_prec),
        'macro_recall':    float(mac_rec),
        'macro_f1':        float(mac_f1),
        'weighted_f1':     float(wgt_f1),
    }


# ── 4. Load & train ───────────────────────────────────────────────────────────

print('=' * 65)
print('  OBD-II Random Forest — Training Pipeline')
print('=' * 65)

df = pd.read_csv(DATASET_PATH)
df = df.drop(columns=[c for c in ['CAR_ID'] if c in df.columns])

print(f'\n[DATA] Loaded {len(df):,} rows × {len(df.columns)} columns')
print(f'[DATA] Target classes  : {df[TARGET].nunique()}')
print()
print(df[TARGET].value_counts().to_string())

X = df[FEATURES].fillna(df[FEATURES].median())
y = df[TARGET]

le = LabelEncoder()
y_encoded = le.fit_transform(y.astype(str))
classes   = le.classes_.astype(str)

X_train, X_test, y_train, y_test = train_test_split(
    X, y_encoded,
    test_size=TEST_SIZE,
    random_state=RANDOM_SEED,
    stratify=y_encoded,
)

print(f'\n[SPLIT] Train : {len(X_train):,}  |  Test : {len(X_test):,}')

print('\n[TRAIN] Fitting Random Forest...')
clf = RandomForestClassifier(**RF_PARAMS)
clf.fit(X_train, y_train)
print('[TRAIN] Done.')

# ── 5. Evaluate on test split ─────────────────────────────────────────────────

y_pred = clf.predict(X_test)

summary = print_metrics(y_test, y_pred, classes, label='Hold-out test set (20%)')

print('[EVAL] Running 5-fold cross-validation...')
cv_scores = cross_val_score(clf, X, y_encoded, cv=5, scoring='accuracy', n_jobs=-1)
print(f'[EVAL] CV accuracy : {cv_scores.mean():.4f} ± {cv_scores.std():.4f}')

# ── 6. Feature importances ────────────────────────────────────────────────────

importances        = pd.Series(clf.feature_importances_, index=FEATURES)
importances_sorted = importances.sort_values(ascending=False)
print('\n[FEAT] Top 10 features:')
print(importances_sorted.head(10).to_string())

# ── 7. Save model & artefacts ────────────────────────────────────────────────

joblib.dump(clf, MODEL_PATH)
joblib.dump(le,  ENCODER_PATH)
print(f'\n[SAVE] Model         → {MODEL_PATH}')
print(f'[SAVE] Label encoder → {ENCODER_PATH}')

metrics_out = {
    **summary,
    'cv_mean':   float(cv_scores.mean()),
    'cv_std':    float(cv_scores.std()),
    'cv_scores': cv_scores.tolist(),
    'classes':   classes.tolist(),
    'feature_importances': importances_sorted.to_dict(),
    'rf_params': RF_PARAMS,
    'n_train':   int(len(X_train)),
    'n_test':    int(len(X_test)),
}
with open('obd2_metrics.json', 'w') as f:
    json.dump(metrics_out, f, indent=2)
print('[SAVE] Metrics       → obd2_metrics.json')

# ── 8. Plots — training evaluation ───────────────────────────────────────────

# Confusion matrix
fig, ax = plt.subplots(figsize=(12, 10))
cm   = confusion_matrix(y_test, y_pred)
disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=classes)
disp.plot(ax=ax, colorbar=True, cmap='Blues', xticks_rotation=45)
ax.set_title('Confusion Matrix — OBD-II Fault Classification (Test Set)', fontsize=13, pad=12)
plt.tight_layout()
plt.savefig('obd2_confusion_matrix.png', dpi=150)
print('[PLOT] Confusion matrix      → obd2_confusion_matrix.png')

# Per-class precision / recall / F1
plot_per_class_metrics(
    y_test, y_pred, classes,
    title_suffix=' (Test Set)',
    save_path='obd2_per_class_metrics.png',
)

# Feature importance bar chart
fig, ax = plt.subplots(figsize=(10, 7))
importances_sorted.plot(kind='barh', ax=ax, color='#1d9e75', edgecolor='none')
ax.invert_yaxis()
ax.set_xlabel('Importance score')
ax.set_title('Random Forest — Feature Importances', fontsize=13)
ax.spines[['top', 'right']].set_visible(False)
plt.tight_layout()
plt.savefig('obd2_feature_importance.png', dpi=150)
print('[PLOT] Feature importance    → obd2_feature_importance.png')

plt.show()


# ═══════════════════════════════════════════════════════════════════════════════
#  INFERENCE — predict fault types from a customer OBD file
# ═══════════════════════════════════════════════════════════════════════════════

def predict_from_file(file_path: str) -> pd.DataFrame:
    """
    Load an OBD file (.numbers / .xlsx / .csv), predict FAILURE_TYPE
    for every row, insert it as the first column, and save the result
    back into the same file (as .csv alongside the original).
    """
    print(f'\n[PREDICT] Loading file: {file_path}')
    ext = os.path.splitext(file_path)[1].lower()

    # ── read the file ─────────────────────────────────────────────────────────
    if ext in ('.xlsx', '.xls'):
        raw = pd.read_excel(file_path)
        print(f'[PREDICT] Format: Excel ({ext})')

    elif ext == '.numbers':
        try:
            from numbers_parser import Document
            doc   = Document(file_path)
            sheet = doc.sheets[0].tables[0]
            rows  = sheet.rows(values_only=True)

            # Find the row that contains the actual column headers
            # (Numbers sometimes has empty rows before the real header)
            header_idx = None
            features_upper = [f.upper() for f in FEATURES]
            for idx, row in enumerate(rows):
                row_vals = [str(c).strip().upper() if c is not None else '' for c in row]
                matches  = sum(1 for v in row_vals if v in features_upper)
                if matches >= 3:          # found the header row
                    header_idx = idx
                    break

            if header_idx is None:
                # No named headers found — assume columns are in FEATURES order
                print('[PREDICT] No named headers found — mapping columns by position')
                n_cols  = len(rows[0])
                headers = FEATURES[:n_cols]
                data_rows = rows
            else:
                headers   = [str(c).strip().upper().replace(' ', '_') if c is not None else f'COL_{i}'
                             for i, c in enumerate(rows[header_idx])]
                data_rows = rows[header_idx + 1:]

            raw = pd.DataFrame(
                [dict(zip(headers, r)) for r in data_rows]
            )
            raw = raw.dropna(how='all').reset_index(drop=True)
            print('[PREDICT] Format: Apple Numbers')
        except ImportError:
            print('[ERROR] numbers-parser not installed. Run: pip install numbers-parser')
            return None

    else:
        for encoding in ('utf-8', 'latin-1', 'cp1252', 'utf-8-sig'):
            try:
                raw = pd.read_csv(file_path, encoding=encoding)
                print(f'[PREDICT] Format: CSV  |  Encoding: {encoding}')
                break
            except UnicodeDecodeError:
                continue
        else:
            raise ValueError(f'Cannot decode {file_path} — save it as UTF-8 CSV.')

    n_cars = len(raw)
    print(f'[PREDICT] {n_cars} car(s) found')

    # ── normalise column names (strip spaces, uppercase) ─────────────────────
    raw.columns = raw.columns.str.strip().str.upper().str.replace(' ', '_').str.replace(r'\s+', '_', regex=True)

    # ── build feature matrix ──────────────────────────────────────────────────
    missing = [f for f in FEATURES if f not in raw.columns]
    if missing:
        print(f'[PREDICT] Missing sensors (defaulted to 0): {missing}')

    X_new = raw.reindex(columns=FEATURES, fill_value=0).fillna(0)

    # ── predict ───────────────────────────────────────────────────────────────
    pred_labels = le.inverse_transform(np.argmax(clf.predict_proba(X_new), axis=1))

    # ── insert FAILURE_TYPE as the first column ───────────────────────────────
    raw.insert(0, 'FAILURE_TYPE', pred_labels)

    # ── print result ──────────────────────────────────────────────────────────
    print(f'\n{"─"*50}')
    if n_cars == 1:
        print(f'  Predicted Fault : {pred_labels[0]}')
    else:
        for i, fault in enumerate(pred_labels, start=1):
            print(f'  Car {i} : {fault}')
    print(f'{"─"*50}')

    # ── save back to the same location as a CSV ───────────────────────────────
    save_path = os.path.splitext(file_path)[0] + '_predicted.csv'
    raw.to_csv(save_path, index=False)
    print(f'[SAVE] File saved → {save_path}')
    return raw


# ── Single-car prediction helper ──────────────────────────────────────────────

def predict_car(sensor_readings: dict) -> dict:
    """
    Predict fault type for a single car given a dict of OBD readings.

    Missing keys default to 0.  Returns predicted fault, confidence,
    and probabilities for all classes.
    """
    row   = {f: sensor_readings.get(f, 0) for f in FEATURES}
    X_new = pd.DataFrame([row])
    proba     = clf.predict_proba(X_new)[0]
    pred_idx  = int(np.argmax(proba))
    return {
        'predicted_failure': le.inverse_transform([pred_idx])[0],
        'confidence':        float(proba[pred_idx]),
        'all_probabilities': {cls: float(p) for cls, p in zip(le.classes_, proba)},
    }


# ── Demo predictions (single-car) ────────────────────────────────────────────

print('\n' + '=' * 65)
print('  Demo — single-car predictions')
print('=' * 65)

demo_cars = [
    ('Healthy', {'ENGINE_RUN_TIME': 3640.2, 'ENGINE_RPM': 1290.4, 'VEHICLE_SPEED': 26.8, 'THROTTLE': 19.6, 'ENGINE_LOAD': 36.8, 'COOLANT_TEMPERATURE': 76.0, 'LONG_TERM_FUEL_TRIM_BANK_1': 1.78, 'SHORT_TERM_FUEL_TRIM_BANK_1': -0.17, 'INTAKE_MANIFOLD_PRESSURE': 37.7, 'FUEL_TANK': 46.6, 'ABSOLUTE_THROTTLE_B': 52.0, 'PEDAL_D': 19.9, 'PEDAL_E': 35.8, 'COMMANDED_THROTTLE_ACTUATOR': 19.7, 'FUEL_AIR_COMMANDED_EQUIV_RATIO': 1.0, 'ABSOLUTE_BAROMETRIC_PRESSURE': 100.8, 'RELATIVE_THROTTLE_POSITION': 2.2, 'INTAKE_AIR_TEMP': 41.7, 'TIMING_ADVANCE': 11.6, 'CATALYST_TEMPERATURE_BANK1_SENSOR1': 480.8, 'CATALYST_TEMPERATURE_BANK1_SENSOR2': 335.1, 'CONTROL_MODULE_VOLTAGE': 13.8, 'COMMANDED_EVAPORATIVE_PURGE': 31.1}),
    ('O2 Sensor Failure', {'ENGINE_RUN_TIME': 3650.9, 'ENGINE_RPM': 1286.0, 'VEHICLE_SPEED': 26.4, 'THROTTLE': 19.7, 'ENGINE_LOAD': 36.9, 'COOLANT_TEMPERATURE': 75.8, 'LONG_TERM_FUEL_TRIM_BANK_1': 16.03, 'SHORT_TERM_FUEL_TRIM_BANK_1': 32.75, 'INTAKE_MANIFOLD_PRESSURE': 38.1, 'FUEL_TANK': 46.8, 'ABSOLUTE_THROTTLE_B': 52.1, 'PEDAL_D': 19.8, 'PEDAL_E': 35.7, 'COMMANDED_THROTTLE_ACTUATOR': 19.4, 'FUEL_AIR_COMMANDED_EQUIV_RATIO': 0.875, 'ABSOLUTE_BAROMETRIC_PRESSURE': 100.8, 'RELATIVE_THROTTLE_POSITION': 2.1, 'INTAKE_AIR_TEMP': 42.0, 'TIMING_ADVANCE': 6.03, 'CATALYST_TEMPERATURE_BANK1_SENSOR1': 536.8, 'CATALYST_TEMPERATURE_BANK1_SENSOR2': 334.1, 'CONTROL_MODULE_VOLTAGE': 13.8, 'COMMANDED_EVAPORATIVE_PURGE': 31.3}),
    ('Engine Overheating', {'ENGINE_RUN_TIME': 3587.9, 'ENGINE_RPM': 1265.7, 'VEHICLE_SPEED': 26.3, 'THROTTLE': 19.6, 'ENGINE_LOAD': 36.6, 'COOLANT_TEMPERATURE': 128.8, 'LONG_TERM_FUEL_TRIM_BANK_1': 1.78, 'SHORT_TERM_FUEL_TRIM_BANK_1': -0.09, 'INTAKE_MANIFOLD_PRESSURE': 37.9, 'FUEL_TANK': 47.2, 'ABSOLUTE_THROTTLE_B': 52.2, 'PEDAL_D': 19.9, 'PEDAL_E': 35.6, 'COMMANDED_THROTTLE_ACTUATOR': 19.6, 'FUEL_AIR_COMMANDED_EQUIV_RATIO': 1.115, 'ABSOLUTE_BAROMETRIC_PRESSURE': 100.7, 'RELATIVE_THROTTLE_POSITION': 2.09, 'INTAKE_AIR_TEMP': 41.6, 'TIMING_ADVANCE': -2.58, 'CATALYST_TEMPERATURE_BANK1_SENSOR1': 562.1, 'CATALYST_TEMPERATURE_BANK1_SENSOR2': 392.8, 'CONTROL_MODULE_VOLTAGE': 13.8, 'COMMANDED_EVAPORATIVE_PURGE': 31.5}),
    ('Thermostat Stuck Open', {'ENGINE_RUN_TIME': 3471.5, 'ENGINE_RPM': 1287.1, 'VEHICLE_SPEED': 26.7, 'THROTTLE': 19.6, 'ENGINE_LOAD': 36.7, 'COOLANT_TEMPERATURE': 54.8, 'LONG_TERM_FUEL_TRIM_BANK_1': -8.42, 'SHORT_TERM_FUEL_TRIM_BANK_1': -10.97, 'INTAKE_MANIFOLD_PRESSURE': 37.9, 'FUEL_TANK': 47.7, 'ABSOLUTE_THROTTLE_B': 52.1, 'PEDAL_D': 20.0, 'PEDAL_E': 35.7, 'COMMANDED_THROTTLE_ACTUATOR': 19.6, 'FUEL_AIR_COMMANDED_EQUIV_RATIO': 1.12, 'ABSOLUTE_BAROMETRIC_PRESSURE': 100.7, 'RELATIVE_THROTTLE_POSITION': 2.03, 'INTAKE_AIR_TEMP': 42.0, 'TIMING_ADVANCE': 11.34, 'CATALYST_TEMPERATURE_BANK1_SENSOR1': 428.1, 'CATALYST_TEMPERATURE_BANK1_SENSOR2': 296.4, 'CONTROL_MODULE_VOLTAGE': 13.8, 'COMMANDED_EVAPORATIVE_PURGE': 31.0}),
    ('Alternator Failure', {'ENGINE_RUN_TIME': 3633.6, 'ENGINE_RPM': 1272.5, 'VEHICLE_SPEED': 26.8, 'THROTTLE': 19.5, 'ENGINE_LOAD': 36.9, 'COOLANT_TEMPERATURE': 75.4, 'LONG_TERM_FUEL_TRIM_BANK_1': 1.76, 'SHORT_TERM_FUEL_TRIM_BANK_1': -0.22, 'INTAKE_MANIFOLD_PRESSURE': 37.9, 'FUEL_TANK': 47.3, 'ABSOLUTE_THROTTLE_B': 52.2, 'PEDAL_D': 19.9, 'PEDAL_E': 35.9, 'COMMANDED_THROTTLE_ACTUATOR': 19.4, 'FUEL_AIR_COMMANDED_EQUIV_RATIO': 1.0, 'ABSOLUTE_BAROMETRIC_PRESSURE': 100.8, 'RELATIVE_THROTTLE_POSITION': 2.04, 'INTAKE_AIR_TEMP': 41.9, 'TIMING_ADVANCE': 11.81, 'CATALYST_TEMPERATURE_BANK1_SENSOR1': 485.9, 'CATALYST_TEMPERATURE_BANK1_SENSOR2': 337.2, 'CONTROL_MODULE_VOLTAGE': 11.435, 'COMMANDED_EVAPORATIVE_PURGE': 32.1}),
    ('Transmission Slip', {'ENGINE_RUN_TIME': 3645.7, 'ENGINE_RPM': 2960.3, 'VEHICLE_SPEED': 10.9, 'THROTTLE': 19.6, 'ENGINE_LOAD': 94.1, 'COOLANT_TEMPERATURE': 76.2, 'LONG_TERM_FUEL_TRIM_BANK_1': 1.70, 'SHORT_TERM_FUEL_TRIM_BANK_1': -0.20, 'INTAKE_MANIFOLD_PRESSURE': 38.0, 'FUEL_TANK': 47.3, 'ABSOLUTE_THROTTLE_B': 52.2, 'PEDAL_D': 19.9, 'PEDAL_E': 35.6, 'COMMANDED_THROTTLE_ACTUATOR': 19.6, 'FUEL_AIR_COMMANDED_EQUIV_RATIO': 0.96, 'ABSOLUTE_BAROMETRIC_PRESSURE': 100.8, 'RELATIVE_THROTTLE_POSITION': 2.11, 'INTAKE_AIR_TEMP': 41.9, 'TIMING_ADVANCE': 7.63, 'CATALYST_TEMPERATURE_BANK1_SENSOR1': 480.7, 'CATALYST_TEMPERATURE_BANK1_SENSOR2': 335.5, 'CONTROL_MODULE_VOLTAGE': 13.8, 'COMMANDED_EVAPORATIVE_PURGE': 30.9}),
    ('Crankshaft Position Sensor Failure', {'ENGINE_RUN_TIME': 3532.3, 'ENGINE_RPM': 37.8, 'VEHICLE_SPEED': 26.5, 'THROTTLE': 19.7, 'ENGINE_LOAD': 15.2, 'COOLANT_TEMPERATURE': -2.8, 'LONG_TERM_FUEL_TRIM_BANK_1': 1.74, 'SHORT_TERM_FUEL_TRIM_BANK_1': 60.6, 'INTAKE_MANIFOLD_PRESSURE': 38.0, 'FUEL_TANK': 47.1, 'ABSOLUTE_THROTTLE_B': 52.1, 'PEDAL_D': 20.0, 'PEDAL_E': 35.7, 'COMMANDED_THROTTLE_ACTUATOR': 19.5, 'FUEL_AIR_COMMANDED_EQUIV_RATIO': 1.0, 'ABSOLUTE_BAROMETRIC_PRESSURE': 100.7, 'RELATIVE_THROTTLE_POSITION': 2.23, 'INTAKE_AIR_TEMP': 41.5, 'TIMING_ADVANCE': 404.7, 'CATALYST_TEMPERATURE_BANK1_SENSOR1': 481.2, 'CATALYST_TEMPERATURE_BANK1_SENSOR2': 337.2, 'CONTROL_MODULE_VOLTAGE': 50.1, 'COMMANDED_EVAPORATIVE_PURGE': 30.6}),
]

for label, readings in demo_cars:
    result = predict_car(readings)
    ok = '✓' if label.lower() in result['predicted_failure'].lower() or result['predicted_failure'].lower() in label.lower() else '✗'
    print(f"\n  {ok} [{label}]")
    print(f"    Predicted  : {result['predicted_failure']}")
    print(f"    Confidence : {result['confidence']*100:.1f}%")

# ── Interactive file-based prediction ────────────────────────────────────────

print('\n' + '=' * 65)
print('  Customer OBD File Prediction')
print('=' * 65)

while True:
    file_input = input(
        '\nEnter the path to a customer OBD CSV file to predict faults\n'
        '(or press Enter to skip): '
    ).strip().strip('"').strip("'")

    if file_input == '':
        print('[INFO] Skipped file prediction.')
        break

    if not os.path.isfile(file_input):
        print(f'[ERROR] File not found: {file_input}')
        print('        Please check the path and try again.')
        continue

    predict_from_file(file_input)

    another = input('\nPredict another file? (y/n): ').strip().lower()
    if another != 'y':
        break

print('\n[DONE] All steps complete.')
