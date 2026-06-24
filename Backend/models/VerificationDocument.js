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
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    role: {
      type: String,
      enum: ['driver', 'workshop', 'admin'],
      required: true,
    },
    kind: {
      type: String,
      enum: [
        'driver_license',
        'business_license',
        'commercial_registration',
        'tax_card',
        'permit',
        'DRIVING_LICENSE',
        'COMMERCIAL_REGISTER',
        'TAX_CARD',
      ],
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
    fileUrl: {
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
    verificationStatus: {
      type: String,
      enum: [
        'pending',
        'auto_verified',
        'needs_manual_review',
        'approved',
        'rejected',
        'ai_processing',
        'ai_verified',
        'ai_rejected',
        'needs_admin_review',
        'admin_approved',
        'admin_rejected',
        'reupload_requested',
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
    detectedDocumentType: {
      type: String,
      enum: [
        'UNKNOWN',
        'TAX_CARD',
        'COMMERCIAL_REGISTER',
        'DRIVING_LICENSE',
      ],
      default: 'UNKNOWN',
    },
    documentType: {
      type: String,
      enum: [
        'UNKNOWN',
        'TAX_CARD',
        'COMMERCIAL_REGISTER',
        'DRIVING_LICENSE',
      ],
      default: 'UNKNOWN',
      index: true,
    },
    extractedText: {
      type: String,
      default: '',
      select: false,
    },
    ocrConfidence: { type: Number, default: null, min: 0, max: 1 },
    confidenceScore: { type: Number, default: null, min: 0, max: 1 },
    qualityStatus: {
      type: String,
      enum: ['good', 'poor', 'low_confidence', 'unreadable', 'unsupported'],
      default: 'low_confidence',
    },
    rejectionReason: {
      type: String,
      default: '',
      trim: true,
    },
    aiConfidence: { type: Number, default: null, min: 0, max: 1 },
    extractedFields: { type: mongoose.Schema.Types.Mixed, default: {} },
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
