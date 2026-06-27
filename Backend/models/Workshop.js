import mongoose from 'mongoose';

const workshopSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    location: {
      type: String,
      required: true,
      trim: true,
    },
    latitude: { type: Number, default: null },
    longitude: { type: Number, default: null },
    phone: { type: String, default: '', trim: true },
    supportsEmergencyService: { type: Boolean, default: true },
    services: {
      type: [String],
      default: [],
    },
    prices: {
      type: Map,
      of: Number,
      default: {},
    },
    serviceDetails: {
      type: [
        {
          name: { type: String, required: true, trim: true },
          price: { type: Number, default: 0, min: 0 },
          durationMins: { type: Number, default: 60, min: 1 },
          emoji: { type: String, default: 'Service', trim: true },
        },
      ],
      default: [],
    },
    workingHours: {
      type: String,
      default: '',
      trim: true,
    },
    availability: {
      type: String,
      enum: ['open', 'busy', 'closed'],
      default: 'open',
    },
    availableSlots: {
      type: [Date],
      default: [],
    },
    images: {
      type: [String],
      default: [],
    },
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    rating: {
      type: Number,
      default: 4.8,
      min: 0,
      max: 5,
    },
    reviewCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    verificationStatus: {
      type: String,
      enum: [
        'pending_upload',
        'ai_processing',
        'ai_verified',
        'ai_rejected',
        'needs_admin_review',
        'admin_approved',
        'admin_rejected',
        'pending',
        'approved',
        'rejected',
      ],
      default: 'pending_upload',
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
    accountStatus: {
      type: String,
      enum: ['pending', 'active', 'suspended', 'rejected', 'deleted'],
      default: 'active',
    },
    customServices: {
      type: [
        {
          name: { type: String, required: true, trim: true },
          emoji: { type: String, default: '🔧' },
          durationMins: { type: Number, default: 30 },
          price: { type: Number, default: 0 },
        },
      ],
      default: [],
    },
  },
  {
    timestamps: true,
  },
);

workshopSchema.index({ accountStatus: 1, isVerified: 1 });
workshopSchema.index({ owner: 1 });
workshopSchema.index({ owner: 1, accountStatus: 1 });
workshopSchema.index({ accountStatus: 1, isVerified: 1, latitude: 1, longitude: 1 });

const Workshop = mongoose.model('Workshop', workshopSchema);

export default Workshop;
