import multer from 'multer';
import Diagnostic from '../models/Diagnostic.js';
import Vehicle from '../models/Vehicle.js';
import Booking from '../models/Booking.js';
import Workshop from '../models/Workshop.js';
import User from '../models/User.js';
import { predictWithMlModel } from '../services/mlBridgeService.js';
import { lookupDTC } from '../services/dtcLookup.js';
import { sendEmail } from '../services/emailService.js';
import { createNotification } from './notificationController.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';

export const diagnosticUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, cb) => {
    const ok = ['application/json', 'text/csv', 'application/vnd.ms-excel'].includes(file.mimetype) ||
      /\.(csv|json)$/i.test(file.originalname);
    cb(ok ? null : Object.assign(new Error('Only CSV and JSON OBD files are allowed'), { statusCode: 400 }), ok);
  },
});

const toPayload = (doc) => ({
  id: doc._id.toString(),
  vehicleId: doc.vehicleId,
  workshopId: doc.workshop?._id?.toString?.() ?? doc.workshop?.toString() ?? null,
  bookingId: doc.booking?._id?.toString?.() ?? doc.booking?.toString() ?? null,
  date: doc.createdAt,
  sourceType: doc.sourceType,
  obdReadings: Object.fromEntries(doc.obdReadings ?? []),
  uploadedFileName: doc.uploadedFileName,
  summary: doc.summary,
  riskLevel: doc.riskLevel,
  health: doc.health,
  faultCodes: doc.faultCodes,
  vitals: doc.vitals,
  recommendations: doc.recommendations,
  aiPrediction: doc.aiPrediction,
  status: doc.status,
  errorMessage: doc.errorMessage,
});

const aliases = {
  coolanttemp: 'COOLANT_TEMPERATURE',
  temperature: 'COOLANT_TEMPERATURE',
  engine_coolant_temperaturec: 'COOLANT_TEMPERATURE',
  rpm: 'ENGINE_RPM',
  engine_rpmrpm: 'ENGINE_RPM',
  speed: 'VEHICLE_SPEED',
  speed_kmh: 'VEHICLE_SPEED',
};

const canonicalKey = (key) => {
  const normalized = key.toString().trim().toLowerCase().replace(/\s+/g, '_');
  return aliases[normalized] ?? normalized.toUpperCase();
};

const sanitizeReadings = (sensorReadings) =>
  Object.fromEntries(
    Object.entries(sensorReadings || {})
      .map(([key, value]) => [canonicalKey(key), Number(value)])
      .filter(([, value]) => Number.isFinite(value)),
  );

const REQUIRED_FEATURES = [
  'ENGINE_RPM',
  'COOLANT_TEMPERATURE',
  'VEHICLE_SPEED',
  'CONTROL_MODULE_VOLTAGE',
  'ENGINE_RUN_TIME',
  'ENGINE_LOAD',
  'THROTTLE',
  'TIMING_ADVANCE',
  'SHORT_TERM_FUEL_TRIM_BANK_1',
  'LONG_TERM_FUEL_TRIM_BANK_1',
  'FUEL_TANK',
  'FUEL_AIR_COMMANDED_EQUIV_RATIO',
  'INTAKE_MANIFOLD_PRESSURE',
  'INTAKE_AIR_TEMP',
  'ABSOLUTE_BAROMETRIC_PRESSURE',
  'ABSOLUTE_THROTTLE_B',
  'RELATIVE_THROTTLE_POSITION',
  'PEDAL_D',
  'PEDAL_E',
  'COMMANDED_THROTTLE_ACTUATOR',
  'CATALYST_TEMPERATURE_BANK1_SENSOR1',
  'CATALYST_TEMPERATURE_BANK1_SENSOR2',
  'COMMANDED_EVAPORATIVE_PURGE',
];

const CORE_FEATURES = ['ENGINE_RPM', 'COOLANT_TEMPERATURE', 'VEHICLE_SPEED'];

const requiredFeatureCount = (readings, required = REQUIRED_FEATURES) =>
  required.filter((key) => key in readings).length;

const normalizedReading = (sensorReadings, keys, fallback = 0) => {
  const normalized = Object.fromEntries(
    Object.entries(sensorReadings || {}).map(([key, value]) => [
      key.toLowerCase().replace(/\s+/g, '_'),
      Number(value) || 0,
    ]),
  );
  for (const key of keys) {
    const value = normalized[key.toLowerCase().replace(/\s+/g, '_')];
    if (value !== undefined) return value;
  }
  return fallback;
};

const FAULT_SEVERITY_MAP = {
  'Engine Overheating': 'critical',
  'Alternator Failure': 'critical',
  'Transmission Slip': 'critical',
  'Throttle Body Fault': 'warning',
  'O2 Sensor Failure': 'warning',
  'Thermostat Stuck Open': 'warning',
};

const FAULT_RECOMMENDATIONS = {
  'Engine Overheating': [
    'Check coolant level and radiator fan.',
    'Inspect the thermostat.',
    'Stop driving if a warning light appears.',
  ],
  'Alternator Failure': [
    'Test battery voltage. It should be around 13.8-14.4V while running.',
    'Inspect or replace the alternator.',
    'Check the drive belt.',
  ],
  'Transmission Slip': [
    'Check transmission fluid level.',
    'Inspect transmission bands.',
    'Schedule transmission service.',
  ],
  'Throttle Body Fault': [
    'Clean the throttle body.',
    'Check the throttle position sensor.',
    'Inspect the idle air control valve.',
  ],
  'O2 Sensor Failure': [
    'Replace the oxygen sensor.',
    'Check fuel mixture and injectors.',
    'Inspect the exhaust system for leaks.',
  ],
  'Thermostat Stuck Open': [
    'Replace the thermostat.',
    'Check the coolant temperature sensor.',
    'Allow the engine to reach operating temperature before heavy driving.',
  ],
};

const buildRuleBasedPrediction = (sensorReadings, faultCodes, mlError) => {
  const coolant = normalizedReading(sensorReadings, ['COOLANT_TEMPERATURE', 'engine_coolant_temperaturec']);
  const rpm = normalizedReading(sensorReadings, ['ENGINE_RPM', 'engine_rpmrpm']);
  const speed = normalizedReading(sensorReadings, ['VEHICLE_SPEED', 'speed_kmh']);
  const voltage = normalizedReading(sensorReadings, ['CONTROL_MODULE_VOLTAGE', 'voltage'], 12.6);
  const shortFuelTrim = normalizedReading(sensorReadings, ['SHORT_TERM_FUEL_TRIM_BANK_1']);
  const longFuelTrim = normalizedReading(sensorReadings, ['LONG_TERM_FUEL_TRIM_BANK_1']);
  const lambda = normalizedReading(sensorReadings, ['FUEL_AIR_COMMANDED_EQUIV_RATIO'], 1.0);
  const engineLoad = normalizedReading(sensorReadings, ['ENGINE_LOAD']);

  const detected = [];
  if (coolant >= 105) detected.push('Engine Overheating');
  if (coolant > 0 && coolant < 76 && rpm > 500) detected.push('Thermostat Stuck Open');
  if (voltage > 0 && voltage < 12.1) detected.push('Alternator Failure');
  if (rpm >= 3500 && engineLoad >= 50 && speed < 45) detected.push('Transmission Slip');
  if (rpm >= 4500 && speed < 20) detected.push('Throttle Body Fault');
  if (shortFuelTrim >= 18 || longFuelTrim >= 10 || lambda < 0.94) detected.push('O2 Sensor Failure');

  const fault = detected[0] ?? null;
  const riskLevel = fault ? (FAULT_SEVERITY_MAP[fault] ?? 'warning') : 'healthy';
  const recommendations = fault
    ? [
        ...(FAULT_RECOMMENDATIONS[fault] ?? []),
        ...(faultCodes.length > 0 ? ['Verify submitted OBD codes with a workshop.'] : []),
      ]
    : ['Continue routine maintenance and rescan if symptoms appear.'];
  const summary = fault ?? 'No fault detected from submitted OBD values';
  return {
    summary,
    riskLevel,
    health: riskLevel === 'healthy' ? 95 : riskLevel === 'warning' ? 72 : 48,
    recommendations,
    aiPrediction: {
      hasFault: Boolean(fault),
      issue: summary,
      confidence: riskLevel === 'critical' ? 0.72 : riskLevel === 'warning' ? 0.6 : 0.5,
      urgency: riskLevel,
      explanation: `Rule-based assessment: coolant ${coolant} C, RPM ${rpm}, speed ${speed} km/h, voltage ${voltage} V, short fuel trim ${shortFuelTrim}%, long fuel trim ${longFuelTrim}%, lambda ${lambda}.`,
      recommendation: recommendations.join(' '),
      technicalNote: `ML service unavailable (${mlError}); used backend rule-based fallback.`,
      estimatedRepair: fault ? 'Workshop inspection recommended' : 'No repair required',
      modelSource: 'backend_rule_based_fallback',
    },
  };
};

const vitalUnitFor = (key) => {
  const normalized = key.toLowerCase();
  if (normalized.includes('temp')) return 'C';
  if (normalized.includes('rpm')) return 'rpm';
  if (normalized.includes('speed')) return 'km/h';
  if (normalized.includes('voltage')) return 'V';
  if (normalized.includes('pressure')) return 'kPa';
  if (normalized.includes('percent') || normalized.includes('throttle') || normalized.includes('load')) {
    return '%';
  }
  return 'value';
};

const toVitals = (sensorReadings) =>
  Object.entries(sensorReadings).map(([key, value]) => ({
    key,
    value: Number(value) || 0,
    unit: vitalUnitFor(key),
  }));

const riskStatusLabel = (riskLevel) => {
  if (riskLevel === 'critical') return 'ALERT';
  if (riskLevel === 'warning') return 'WARNING';
  return 'SAFE';
};

const escapeHtml = (value = '') =>
  String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

const buildReportText = (diagnostic) => {
  const ai = diagnostic.aiPrediction || {};
  const lines = [
    `Prediction: ${ai.issue || diagnostic.summary}`,
    `Status: ${riskStatusLabel(diagnostic.riskLevel)}`,
    `Confidence: ${Math.round((Number(ai.confidence) || 0) * 100)}%`,
    `Health score: ${diagnostic.health}%`,
    '',
    `Summary: ${diagnostic.summary}`,
    ai.explanation ? `Explanation: ${ai.explanation}` : '',
    ai.recommendation ? `AI recommendation: ${ai.recommendation}` : '',
    ai.technicalNote ? `Technical note: ${ai.technicalNote}` : '',
    '',
    'Recommendations:',
    ...(diagnostic.recommendations || []).map((item) => `- ${item}`),
  ].filter((line) => line !== '');

  if (diagnostic.faultCodes?.length) {
    lines.push('', 'Fault codes:');
    diagnostic.faultCodes.forEach((fault) => {
      lines.push(`- ${fault.code}: ${fault.description} (${fault.level})`);
    });
  }

  return lines.join('\n');
};

const notifyDiagnosticReady = async ({ diagnostic, ownerId, vehicle }) => {
  try {
    const reportId = diagnostic._id.toString();
    const riskLabel = riskStatusLabel(diagnostic.riskLevel);
    const driver = await User.findById(ownerId).select('name email');
    const title = 'AI Diagnostic Report Ready';
    const body =
      diagnostic.riskLevel === 'healthy'
        ? 'Your vehicle AI diagnostic report is ready. No urgent fault was detected.'
        : `Your vehicle AI diagnostic report is ready with ${riskLabel} status. Tap to view details.`;

    await createNotification({
      userId: ownerId,
      title,
      body,
      type: 'ai_report',
      relatedEntityId: reportId,
      data: {
        reportId,
        diagnosticId: reportId,
        vehicleId: diagnostic.vehicleId,
        riskLevel: diagnostic.riskLevel,
      },
    });

    if (!driver?.email) return;

    const reportText = buildReportText(diagnostic);
    const vehicleName = [vehicle.make, vehicle.model, vehicle.year].filter(Boolean).join(' ') || 'your vehicle';
    const html = `
      <div style="font-family:Arial,sans-serif;line-height:1.6;color:#111827">
        <h2 style="margin:0 0 12px">Your Salahny AI Diagnostic Report</h2>
        <p>Hello ${escapeHtml(driver.name || 'Driver')},</p>
        <p>Your AI diagnostic report for ${escapeHtml(vehicleName)} is ready.</p>
        <p><strong>Status:</strong> ${escapeHtml(riskLabel)}</p>
        <p><strong>Prediction:</strong> ${escapeHtml(diagnostic.aiPrediction?.issue || diagnostic.summary)}</p>
        <p><strong>Confidence:</strong> ${Math.round((Number(diagnostic.aiPrediction?.confidence) || 0) * 100)}%</p>
        <pre style="white-space:pre-wrap;background:#f3f4f6;border-radius:8px;padding:12px">${escapeHtml(reportText)}</pre>
        ${
          diagnostic.riskLevel === 'critical'
            ? '<p><strong>Safety note:</strong> Please avoid driving if the vehicle feels unsafe and contact a workshop.</p>'
            : ''
        }
        <p>Thank you,<br/>Salahny Team</p>
      </div>`;

    const emailResult = await sendEmail({
      to: driver.email,
      subject: 'Your Salahny AI Diagnostic Report',
      text: `Hello ${driver.name || 'Driver'},\n\nYour AI diagnostic report for ${vehicleName} is ready.\n\n${reportText}\n\nThank you,\nSalahny Team`,
      html,
    });

    if (!emailResult.sent) {
      console.warn('[diagnostics] AI report email was not sent', {
        reportId,
        userId: ownerId.toString(),
        reason: emailResult.reason,
        error: emailResult.error,
      });
    }
  } catch (error) {
    console.error('[diagnostics] notification/email side effect failed', {
      reportId: diagnostic?._id?.toString?.(),
      error: error.message,
    });
  }
};

const createDiagnostic = async ({
  req,
  vehicleId,
  readings,
  faultCodes,
  sourceType,
  uploadedFileName = '',
  booking = null,
  workshop = null,
  driver = null,
}) => {
  if (!vehicleId) throw Object.assign(new Error('vehicleId is required'), { statusCode: 400 });
  const ownerId = driver ?? req.user._id;
  const vehicle = await Vehicle.findOne({ _id: vehicleId, owner: ownerId });
  if (!vehicle) throw Object.assign(new Error('Vehicle not found for the logged-in user'), { statusCode: 404 });
  if (sourceType === 'manual') {
    if (requiredFeatureCount(readings) < REQUIRED_FEATURES.length) {
      const missing = REQUIRED_FEATURES.filter((key) => !(key in readings));
      throw Object.assign(new Error(`Missing required OBD features: ${missing.join(', ')}`), { statusCode: 400 });
    }
  } else if (requiredFeatureCount(readings, CORE_FEATURES) < CORE_FEATURES.length) {
    throw Object.assign(
      new Error('OBD file must contain at least ENGINE_RPM, COOLANT_TEMPERATURE, and VEHICLE_SPEED'),
      { statusCode: 400 },
    );
  }
  let template;
  let status = 'success';
  let errorMessage = '';
  try {
    const prediction = await predictWithMlModel(readings);
    const health =
      prediction.risk_level === 'healthy'
        ? 96
        : prediction.risk_level === 'warning'
          ? Math.max(55, 100 - Math.round(prediction.confidence * 35))
          : Math.max(25, 100 - Math.round(prediction.confidence * 70));
    template = {
      summary: prediction.predicted_failure,
      riskLevel: prediction.risk_level,
      health,
      recommendations: prediction.recommendations,
      aiPrediction: {
        hasFault: prediction.risk_level !== 'healthy',
        issue: prediction.predicted_failure,
        confidence: prediction.confidence,
        urgency: prediction.risk_level,
        explanation: `AI analyzed the submitted OBD readings.`,
        recommendation: prediction.recommendations.join(' '),
        technicalNote: `Model source: ${prediction.model_source || 'ml_service'}`,
        estimatedRepair: prediction.predicted_failure,
        modelSource: prediction.model_source || 'ml_service',
      },
    };
  } catch (error) {
    template = buildRuleBasedPrediction(readings, faultCodes, error.message);
    status = 'failed';
    errorMessage = error.message;
  }
  const diagnostic = await Diagnostic.create({
    user: ownerId,
    vehicleId,
    workshop,
    booking,
    sourceType,
    obdReadings: readings,
    uploadedFileName,
    faultCodes: faultCodes.map((code) => {
      const dtc = lookupDTC(code);
      return {
        code,
        description: dtc.description,
        level: dtc.severity || template.riskLevel,
      };
    }),
    vitals: toVitals(readings),
    status,
    errorMessage,
    ...template,
  });
  await Vehicle.findByIdAndUpdate(vehicleId, { health: template.health });
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Diagnostic scan created',
    target: vehicleId,
    details: template.summary,
  });
  await notifyDiagnosticReady({ diagnostic, ownerId, vehicle });
  return diagnostic;
};

export const runDiagnosticScan = asyncHandler(async (req, res) => {
  const readings = sanitizeReadings(req.body.sensorReadings || req.body.obdReadings);
  const faultCodes = Array.isArray(req.body.faultCodes) ? req.body.faultCodes.map(String) : [];
  try {
    const diagnostic = await createDiagnostic({
      req,
      vehicleId: req.body.vehicleId,
      readings,
      faultCodes,
      sourceType: req.body.sourceType || 'manual',
    });
    res.status(201).json({ success: true, data: toPayload(diagnostic) });
  } catch (error) {
    res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
});

const parseCsv = (text) => {
  const [headerLine, valueLine] = text.trim().split(/\r?\n/);
  if (!headerLine || !valueLine) throw new Error('CSV must contain headers and one data row');
  const headers = headerLine.split(',').map((value) => value.trim());
  const values = valueLine.split(',').map((value) => value.trim());
  return Object.fromEntries(headers.map((header, index) => [header, values[index]]));
};

export const uploadObdFile = asyncHandler(async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'file is required' });
  const rawText = req.file.buffer.toString('utf8');
  let parsed;
  try {
    parsed = /\.json$/i.test(req.file.originalname) ? JSON.parse(rawText) : parseCsv(rawText);
  } catch (error) {
    return res.status(400).json({ success: false, message: `Could not parse OBD file: ${error.message}` });
  }
  const readings = sanitizeReadings(parsed.sensorReadings ?? parsed.obdReadings ?? parsed);
  const faultCodes = Array.isArray(parsed.faultCodes) ? parsed.faultCodes.map(String) : [];
  try {
    const diagnostic = await createDiagnostic({
      req,
      vehicleId: req.body.vehicleId,
      readings,
      faultCodes,
      sourceType: 'file_upload',
      uploadedFileName: req.file.originalname,
    });
    res.status(201).json({ success: true, data: toPayload(diagnostic) });
  } catch (error) {
    res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
});

const getWorkshopBookingContext = async (req) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });
  const booking = await Booking.findById(req.params.bookingId);
  if (!workshop || !booking || booking.workshop.toString() !== workshop._id.toString()) {
    throw Object.assign(new Error('Booking not found for this workshop'), { statusCode: 404 });
  }
  if (!booking.vehicleId) {
    throw Object.assign(new Error('This booking does not include a vehicle ID'), { statusCode: 409 });
  }
  return { workshop, booking };
};

export const runWorkshopBookingDiagnostic = asyncHandler(async (req, res) => {
  try {
    const { workshop, booking } = await getWorkshopBookingContext(req);
    const readings = sanitizeReadings(req.body.sensorReadings || req.body.obdReadings);
    const faultCodes = Array.isArray(req.body.faultCodes) ? req.body.faultCodes.map(String) : [];
    const diagnostic = await createDiagnostic({
      req,
      vehicleId: booking.vehicleId,
      readings,
      faultCodes,
      sourceType: req.body.sourceType || 'manual',
      booking: booking._id,
      workshop: workshop._id,
      driver: booking.user,
    });
    res.status(201).json({ success: true, data: toPayload(diagnostic) });
  } catch (error) {
    res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
});

export const uploadWorkshopBookingObdFile = asyncHandler(async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'file is required' });
  try {
    const { workshop, booking } = await getWorkshopBookingContext(req);
    const rawText = req.file.buffer.toString('utf8');
    const parsed = /\.json$/i.test(req.file.originalname) ? JSON.parse(rawText) : parseCsv(rawText);
    const readings = sanitizeReadings(parsed.sensorReadings ?? parsed.obdReadings ?? parsed);
    const faultCodes = Array.isArray(parsed.faultCodes) ? parsed.faultCodes.map(String) : [];
    const diagnostic = await createDiagnostic({
      req,
      vehicleId: booking.vehicleId,
      readings,
      faultCodes,
      sourceType: 'file_upload',
      uploadedFileName: req.file.originalname,
      booking: booking._id,
      workshop: workshop._id,
      driver: booking.user,
    });
    res.status(201).json({ success: true, data: toPayload(diagnostic) });
  } catch (error) {
    res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
});

export const getDiagnosticHistory = asyncHandler(async (req, res) => {
  const filter = req.user.role === 'admin' ? {} : { user: req.user._id };
  const diagnostics = await Diagnostic.find(filter).sort({ createdAt: -1 });
  res.status(200).json({ success: true, data: diagnostics.map(toPayload) });
});

export const getDiagnosticById = asyncHandler(async (req, res) => {
  const diagnostic = await Diagnostic.findById(req.params.id);
  if (!diagnostic) return res.status(404).json({ success: false, message: 'Diagnostic not found' });
  if (req.user.role !== 'admin' && diagnostic.user.toString() !== req.user._id.toString()) {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }
  res.status(200).json({ success: true, data: toPayload(diagnostic) });
});

export const getWorkshopBookingDiagnostics = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });
  const booking = await Booking.findById(req.params.bookingId);
  if (!workshop || !booking || booking.workshop.toString() !== workshop._id.toString()) {
    return res.status(404).json({ success: false, message: 'Booking not found for this workshop' });
  }
  const diagnostics = await Diagnostic.find({
    $or: [{ booking: booking._id }, { user: booking.user }],
  }).sort({ createdAt: -1 });
  res.status(200).json({ success: true, data: diagnostics.map(toPayload) });
});
