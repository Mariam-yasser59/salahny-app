const mongoose = require('mongoose');

const diagnosticSchema = new mongoose.Schema(
  {
    userId:          String,
    vehicleId:       String,
    vehicleInfo:     String,
    sensorReadings:  Object,
    faultCodes:      [String],
    predictedFailure:String,
    confidence:      Number,
    riskLevel:       String,
    isHealthy:       Boolean,
    healthScore:     Number,
    recommendations: [String],
    allProbabilities:Object,
  },
  {
    timestamps: true,
    toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } },
  },
);

module.exports = mongoose.model('Diagnostic', diagnosticSchema);
