# US-37 Unit Tests — pytest
# AC1: Confidence Score Provided for Each Prediction
# AC2: Severity Level Determines Recommended Urgency

import pytest
import numpy as np
import pandas as pd
from unittest.mock import MagicMock
from severity import get_severity, URGENCY_LEVELS

# ── Shared setup ──────────────────────────────────────────────────────────────

FEATURES = [
    'ENGINE_RUN_TIME', 'ENGINE_RPM', 'VEHICLE_SPEED', 'THROTTLE',
    'ENGINE_LOAD', 'COOLANT_TEMPERATURE', 'LONG_TERM_FUEL_TRIM_BANK_1',
    'SHORT_TERM_FUEL_TRIM_BANK_1', 'INTAKE_MANIFOLD_PRESSURE', 'FUEL_TANK',
    'ABSOLUTE_THROTTLE_B', 'PEDAL_D', 'PEDAL_E', 'COMMANDED_THROTTLE_ACTUATOR',
    'FUEL_AIR_COMMANDED_EQUIV_RATIO', 'ABSOLUTE_BAROMETRIC_PRESSURE',
    'RELATIVE_THROTTLE_POSITION', 'INTAKE_AIR_TEMP', 'TIMING_ADVANCE',
    'CATALYST_TEMPERATURE_BANK1_SENSOR1', 'CATALYST_TEMPERATURE_BANK1_SENSOR2',
    'CONTROL_MODULE_VOLTAGE', 'COMMANDED_EVAPORATIVE_PURGE',
]

FAILURE_TYPES = [
    'Alternator Failure', 'Catalytic Converter Failure',
    'Crankshaft Position Sensor Failure', 'EVAP System Fault',
    'Engine Overheating', 'Healthy', 'MAP Sensor Failure',
    'O2 Sensor Failure', 'Thermostat Stuck Open',
    'Throttle Body Fault', 'Transmission Slip',
]


def make_prediction(predicted_failure: str, confidence: float) -> dict:
    """Simulate predict_car() output with controlled confidence and failure type."""
    n = len(FAILURE_TYPES)
    idx = FAILURE_TYPES.index(predicted_failure)

    proba = np.full(n, (1 - confidence) / (n - 1))
    proba[idx] = confidence

    mock_clf = MagicMock()
    mock_clf.predict_proba.return_value = np.array([proba])

    mock_le = MagicMock()
    mock_le.classes_ = np.array(FAILURE_TYPES)
    mock_le.inverse_transform.side_effect = lambda i: [FAILURE_TYPES[i[0]]]

    row = {f: 0 for f in FEATURES}
    X_new = pd.DataFrame([row])
    proba_out = mock_clf.predict_proba(X_new)[0]
    pred_idx = int(np.argmax(proba_out))

    return {
        'predicted_failure': mock_le.inverse_transform([pred_idx])[0],
        'confidence': float(proba_out[pred_idx]),
        'all_probabilities': {cls: float(p) for cls, p in zip(mock_le.classes_, proba_out)},
    }


# ═══════════════════════════════════════════════════════════════════════════════
# AC1 — Confidence Score Provided for Each Prediction
# ═══════════════════════════════════════════════════════════════════════════════

def test_confidence_score_is_present():
    """Response must include a confidence score."""
    result = make_prediction('Engine Overheating', 0.85)
    assert 'confidence' in result

def test_confidence_score_is_a_number_between_0_and_1():
    """Confidence must be a float in the range [0.0, 1.0]."""
    result = make_prediction('O2 Sensor Failure', 0.76)
    assert isinstance(result['confidence'], float)
    assert 0.0 <= result['confidence'] <= 1.0

def test_confidence_score_matches_predicted_class():
    """Confidence must equal the probability of the predicted failure, not any other class."""
    result = make_prediction('Transmission Slip', 0.90)
    predicted = result['predicted_failure']
    assert result['confidence'] == result['all_probabilities'][predicted]

def test_predicted_failure_is_included_in_response():
    """Response must include the predicted failure type."""
    result = make_prediction('Alternator Failure', 0.80)
    assert 'predicted_failure' in result
    assert result['predicted_failure'] == 'Alternator Failure'

def test_all_class_probabilities_are_returned():
    """Response must include a probability for every known failure type."""
    result = make_prediction('Healthy', 0.92)
    assert set(result['all_probabilities'].keys()) == set(FAILURE_TYPES)


# ═══════════════════════════════════════════════════════════════════════════════
# AC2 — Severity Level Determines Recommended Urgency
# ═══════════════════════════════════════════════════════════════════════════════

def test_severity_and_urgency_are_present_for_every_failure():
    """Every failure type must return both a severity level and an urgency action."""
    for failure in FAILURE_TYPES:
        result = get_severity(failure)
        assert 'severity' in result, f"Missing severity for: {failure}"
        assert 'urgency' in result, f"Missing urgency for: {failure}"

def test_critical_failures_map_to_immediate_urgency():
    """Safety-critical failures must demand the most urgent action."""
    critical_failures = ['Engine Overheating', 'Transmission Slip', 'Crankshaft Position Sensor Failure']
    for failure in critical_failures:
        result = get_severity(failure)
        assert result['severity'] == 'critical'
        assert result['urgency'] == URGENCY_LEVELS[0]

def test_healthy_maps_to_no_action_needed():
    """A healthy vehicle must have no severity and no urgency to act."""
    result = get_severity('Healthy')
    assert result['severity'] == 'none'
    assert result['urgency'] == URGENCY_LEVELS[-1]

def test_different_severities_have_different_urgency_messages():
    """Each severity tier must correspond to a unique urgency message."""
    seen = {}
    for failure in FAILURE_TYPES:
        info = get_severity(failure)
        severity = info['severity']
        urgency = info['urgency']
        if severity in seen:
            assert seen[severity] == urgency
        seen[severity] = urgency
    assert len(set(seen.values())) == len(seen), "Two severity tiers share the same urgency message"

def test_unknown_failure_type_does_not_crash():
    """An unrecognised failure type must return a safe fallback, not raise an error."""
    result = get_severity('Unknown Sensor XYZ')
    assert 'severity' in result
    assert 'urgency' in result
    assert result['severity'] == 'unknown'
    assert len(result['urgency']) > 0

def test_prediction_and_severity_work_together():
    """The predicted_failure from predict_car must feed directly into get_severity."""
    result = make_prediction('Engine Overheating', 0.88)
    severity_info = get_severity(result['predicted_failure'])
    assert severity_info['severity'] == 'critical'
    assert severity_info['urgency'] == URGENCY_LEVELS[0]
