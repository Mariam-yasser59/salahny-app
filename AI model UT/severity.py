# Severity levels and recommended urgency for each predicted failure type.
# Ordered from most-urgent (index 0) to least-urgent (index -1).
URGENCY_LEVELS = [
    'Stop driving immediately — seek emergency service',
    'Address within 24 hours',
    'Schedule service within the week',
    'Schedule service when convenient',
    'No action needed',
]

SEVERITY_MAP = {
    'Healthy':                            {'severity': 'none',     'urgency': URGENCY_LEVELS[4]},
    'EVAP System Fault':                  {'severity': 'low',      'urgency': URGENCY_LEVELS[3]},
    'Thermostat Stuck Open':              {'severity': 'low',      'urgency': URGENCY_LEVELS[3]},
    'Catalytic Converter Failure':        {'severity': 'medium',   'urgency': URGENCY_LEVELS[2]},
    'MAP Sensor Failure':                 {'severity': 'medium',   'urgency': URGENCY_LEVELS[2]},
    'O2 Sensor Failure':                  {'severity': 'medium',   'urgency': URGENCY_LEVELS[2]},
    'Throttle Body Fault':                {'severity': 'medium',   'urgency': URGENCY_LEVELS[2]},
    'Alternator Failure':                 {'severity': 'high',     'urgency': URGENCY_LEVELS[1]},
    'Engine Overheating':                 {'severity': 'critical', 'urgency': URGENCY_LEVELS[0]},
    'Transmission Slip':                  {'severity': 'critical', 'urgency': URGENCY_LEVELS[0]},
    'Crankshaft Position Sensor Failure': {'severity': 'critical', 'urgency': URGENCY_LEVELS[0]},
}


def get_severity(failure_type: str) -> dict:
    """Return severity level and recommended urgency for a predicted failure type."""
    return SEVERITY_MAP.get(
        failure_type,
        {'severity': 'unknown', 'urgency': 'Consult a mechanic'},
    )
