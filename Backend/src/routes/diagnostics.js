const express = require('express');
const axios = require('axios');
const Diagnostic = require('../models/Diagnostic');
const Vehicle = require('../models/Vehicle');
const { auth } = require('../middleware/auth');

const router = express.Router();

// POST /diagnostics/scan
router.post('/scan', auth, async (req, res) => {
  try {
    const { vehicleId, sensorReadings, faultCodes } = req.body;

    const vehicle = await Vehicle.findById(vehicleId);
    if (!vehicle) return res.status(404).json({ detail: 'Vehicle not found' });

    // Call Python ML microservice
    let prediction;
    try {
      const mlRes = await axios.post(`${process.env.ML_SERVICE_URL}/predict`, { sensor_readings: sensorReadings });
      prediction = mlRes.data;
    } catch {
      return res.status(503).json({ detail: 'ML service unavailable — ensure the Python ML service is running' });
    }

    const healthScore =
      prediction.risk_level === 'critical' ? Math.max(20, 100 - Math.round(prediction.confidence * 80)) :
      prediction.risk_level === 'warning'  ? Math.max(50, 100 - Math.round(prediction.confidence * 40)) : 100;

    await Vehicle.findByIdAndUpdate(vehicleId, { health: healthScore });

    const report = await Diagnostic.create({
      userId: req.user._id.toString(),
      vehicleId,
      vehicleInfo: `${vehicle.year} ${vehicle.make} ${vehicle.model}`,
      sensorReadings,
      faultCodes: faultCodes || [],
      predictedFailure: prediction.predicted_failure,
      confidence: prediction.confidence,
      riskLevel: prediction.risk_level,
      isHealthy: prediction.is_healthy,
      healthScore,
      recommendations: prediction.recommendations || [],
      allProbabilities: prediction.all_probabilities || {},
    });

    res.status(201).json(report);
  } catch (err) {
    res.status(500).json({ detail: err.message });
  }
});

// GET /diagnostics/reports
router.get('/reports', auth, async (req, res) => {
  const query = { userId: req.user._id.toString() };
  if (req.query.vehicleId) query.vehicleId = req.query.vehicleId;
  const reports = await Diagnostic.find(query).sort({ createdAt: -1 }).limit(50);
  res.json(reports);
});

// GET /diagnostics/:id
router.get('/:id', auth, async (req, res) => {
  try {
    const report = await Diagnostic.findById(req.params.id);
    if (!report) return res.status(404).json({ detail: 'Report not found' });
    if (report.userId !== req.user._id.toString() && req.user.role !== 'workshop') {
      return res.status(403).json({ detail: 'Access denied' });
    }
    res.json(report);
  } catch {
    res.status(400).json({ detail: 'Invalid report ID' });
  }
});

module.exports = router;
