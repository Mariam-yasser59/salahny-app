const mongoose = require('mongoose');

const obdPredictionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    vehicle: { type: mongoose.Schema.Types.ObjectId, ref: 'Vehicle' },
    sensorReadings: { type: Object, default: {} },
    faultCodes: { type: [String], default: [] },
    predictedFailure: String,
    confidence: Number,
    riskLevel: { type: String, enum: ['healthy', 'warning', 'critical', 'unknown'], default: 'unknown' },
    recommendations: { type: [String], default: [] },
    status: { type: String, enum: ['new', 'reviewed', 'resolved'], default: 'new' },
  },
  { timestamps: true, toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } } },
);

module.exports = mongoose.model('ObdPrediction', obdPredictionSchema);
