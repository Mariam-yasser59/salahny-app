import mongoose from 'mongoose';

const diagnosticSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    vehicleId: {
      type: String,
      required: true,
      trim: true,
    },
    summary: {
      type: String,
      required: true,
      trim: true,
    },
    riskLevel: {
      type: String,
      enum: ['healthy', 'warning', 'critical'],
      required: true,
    },
    health: {
      type: Number,
      required: true,
      min: 0,
      max: 100,
    },
    faultCodes: {
      type: [
        {
          code: { type: String, required: true },
          description: { type: String, required: true },
          level: {
            type: String,
            enum: ['healthy', 'warning', 'critical'],
            required: true,
          },
        },
      ],
      default: [],
    },
    vitals: {
      type: [
        {
          key: { type: String, required: true },
          value: { type: Number, required: true },
          unit: { type: String, required: true },
        },
      ],
      default: [],
    },
    recommendations: {
      type: [String],
      default: [],
    },
    aiPrediction: {
      issue: String,
      confidence: Number,
      urgency: {
        type: String,
        enum: ['healthy', 'warning', 'critical'],
      },
      recommendation: String,
      technicalNote: String,
      estimatedRepair: String,
    },
  },
  {
    timestamps: true,
  },
);

const Diagnostic = mongoose.model('Diagnostic', diagnosticSchema);

export default Diagnostic;
