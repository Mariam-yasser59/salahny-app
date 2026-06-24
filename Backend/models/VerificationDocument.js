import mongoose from 'mongoose';

const verificationDocumentSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    workshop: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Workshop',
      default: null,
      index: true,
    },
    kind: {
      type: String,
      enum: ['driver_license', 'business_license', 'commercial_registration', 'permit'],
      required: true,
    },
    originalName: {
      type: String,
      required: true,
      trim: true,
    },
    mimeType: {
      type: String,
      enum: ['image/jpeg', 'image/png', 'application/pdf'],
      required: true,
    },
    sizeBytes: {
      type: Number,
      required: true,
      max: 5 * 1024 * 1024,
    },
    data: {
      type: Buffer,
      select: false,
    },
    storageProvider: {
      type: String,
      enum: ['mongodb', 'cloudinary'],
      default: 'mongodb',
    },
    externalUrl: {
      type: String,
      default: null,
    },
    storageKey: {
      type: String,
      default: null,
    },
    status: {
      type: String,
      enum: [
        'pending_upload',
        'ai_processing',
        'ai_verified',
        'ai_rejected',
        'needs_admin_review',
        'admin_approved',
        'admin_rejected',
        // Backward-compatible legacy values kept for existing records.
        'pending',
        'approved',
        'rejected',
      ],
      default: 'pending',
    },
    aiVerificationStatus: {
      type: String,
      enum: [
        'pending_upload',
        'ai_processing',
        'ai_verified',
        'ai_rejected',
        'needs_admin_review',
      ],
      default: 'pending_upload',
    },
    aiConfidence: { type: Number, default: null, min: 0, max: 1 },
    aiExtractedFields: { type: mongoose.Schema.Types.Mixed, default: {} },
    aiIssues: { type: [String], default: [] },
    aiCheckedAt: { type: Date, default: null },
    reviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    reviewNotes: {
      type: String,
      default: '',
      trim: true,
    },
    reviewedAt: { type: Date, default: null },
  },
  { timestamps: true },
);

const VerificationDocument = mongoose.model(
  'VerificationDocument',
  verificationDocumentSchema,
);

export default VerificationDocument;
