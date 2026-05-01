import Diagnostic from '../models/Diagnostic.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';

const reports = [
  {
    summary: 'Cooling system and fuel mixture anomaly detected',
    riskLevel: 'critical',
    health: 61,
    faultCodes: [
      {
        code: 'P0420',
        description: 'Catalyst system efficiency below threshold',
        level: 'warning',
      },
      {
        code: 'P0171',
        description: 'System too lean (Bank 1)',
        level: 'critical',
      },
    ],
    vitals: [
      { key: 'RPM', value: 3200, unit: 'rpm' },
      { key: 'Coolant Temp', value: 110, unit: '°C' },
      { key: 'MAP', value: 75, unit: 'kPa' },
      { key: 'Battery', value: 12.4, unit: 'V' },
    ],
    recommendations: [
      'Inspect radiator, coolant level, and thermostat.',
      'Check fuel delivery and vacuum leaks.',
      'Avoid long-distance driving until repair is completed.',
    ],
    aiPrediction: {
      issue: 'Cooling System / Fuel Mixture Anomaly',
      confidence: 0.94,
      urgency: 'critical',
      recommendation:
        'Inspect radiator flow, coolant level, and intake/fuel mixture immediately.',
      technicalNote:
        'High coolant temperature with elevated RPM and lean fuel code pattern indicate a likely cooling restriction and air-fuel imbalance.',
      estimatedRepair: 'Cooling inspection + fuel system diagnosis',
    },
  },
  {
    summary: 'Battery and charging weakness detected',
    riskLevel: 'warning',
    health: 74,
    faultCodes: [
      {
        code: 'P0562',
        description: 'System voltage low',
        level: 'warning',
      },
    ],
    vitals: [
      { key: 'Battery', value: 11.8, unit: 'V' },
      { key: 'RPM', value: 2500, unit: 'rpm' },
      { key: 'Alternator Load', value: 81, unit: '%' },
    ],
    recommendations: [
      'Test battery and alternator.',
      'Inspect battery terminals for corrosion.',
    ],
    aiPrediction: {
      issue: 'Battery / Charging Weakness',
      confidence: 0.79,
      urgency: 'warning',
      recommendation: 'Inspect battery charge state and alternator output.',
      technicalNote:
        'Voltage trend suggests weak charging performance under moderate engine load.',
      estimatedRepair: 'Battery & alternator test',
    },
  },
  {
    summary: 'Vehicle operating normally',
    riskLevel: 'healthy',
    health: 96,
    faultCodes: [],
    vitals: [
      { key: 'RPM', value: 1800, unit: 'rpm' },
      { key: 'Coolant Temp', value: 91, unit: '°C' },
      { key: 'Battery', value: 12.8, unit: 'V' },
    ],
    recommendations: [
      'Continue routine maintenance schedule.',
      'Repeat OBD scan in 2 weeks.',
    ],
    aiPrediction: {
      issue: 'Normal Operating State',
      confidence: 0.88,
      urgency: 'healthy',
      recommendation: 'No urgent action needed. Continue routine maintenance.',
      technicalNote: 'All key OBD values are within expected range.',
      estimatedRepair: 'No repair required',
    },
  },
];

const toPayload = (doc) => ({
  id: doc._id.toString(),
  vehicleId: doc.vehicleId,
  date: doc.createdAt,
  summary: doc.summary,
  riskLevel: doc.riskLevel,
  health: doc.health,
  faultCodes: doc.faultCodes,
  vitals: doc.vitals,
  recommendations: doc.recommendations,
  aiPrediction: doc.aiPrediction,
});

export const runDiagnosticScan = asyncHandler(async (req, res) => {
  const { vehicleId = 'default_vehicle' } = req.body;
  const seed = vehicleId
    .split('')
    .reduce((sum, char) => sum + char.charCodeAt(0), 0);
  const template = reports[seed % reports.length];

  const diagnostic = await Diagnostic.create({
    user: req.user._id,
    vehicleId,
    ...template,
  });

  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Diagnostic scan created',
    target: vehicleId,
    details: template.summary,
  });

  res.status(201).json({
    success: true,
    data: toPayload(diagnostic),
  });
});

export const getDiagnosticHistory = asyncHandler(async (req, res) => {
  const diagnostics = await Diagnostic.find({ user: req.user._id }).sort({
    createdAt: -1,
  });

  res.status(200).json({
    success: true,
    data: diagnostics.map(toPayload),
  });
});
