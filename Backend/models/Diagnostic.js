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
    workshop: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Workshop',
      default: null,
      index: true,
    },
    booking: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
      default: null,
      index: true,
    },
    sourceType: {
      type: String,
      enum: ['manual', 'file_upload', 'obd_live'],
      default: 'manual',
    },
    obdReadings: {
      type: Map,
      of: Number,
      default: {},
    },
    uploadedFileName: {
      type: String,
      default: '',
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
      hasFault: {
        type: Boolean,
        default: false,
      },
      issue: String,
      detectedIssue: String,
      predictedIssue: String,
      predictionHorizon: String,
      predictionReason: String,
      confidence: Number,
      urgency: {
        type: String,
        enum: ['healthy', 'warning', 'critical'],
      },
      explanation: String,
      recommendation: String,
      technicalNote: String,
      estimatedRepair: String,
      modelSource: String,
    },
    status: {
      type: String,
      enum: ['success', 'failed'],
      default: 'success',
    },
    errorMessage: {
      type: String,
      default: '',
    },
    sentToDriverAt: {
      type: Date,
      default: null,
    },
    sentToDriverBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    repairTaskCreatedAt: {
      type: Date,
      default: null,
    },
    repairTaskCreatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
  },
  {
    timestamps: true,
  },
);
diagnosticSchema.index({ user: 1, createdAt: -1 });
diagnosticSchema.index({ workshop: 1, booking: 1, createdAt: -1 });

const Diagnostic = mongoose.model('Diagnostic', diagnosticSchema);

export default Diagnostic;
