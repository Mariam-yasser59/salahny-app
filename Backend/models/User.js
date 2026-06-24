import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    phone: {
      type: String,
      default: '',
      trim: true,
    },
    password: {
      type: String,
      required: true,
      minlength: 6,
      select: false,
    },
    role: {
      type: String,
      enum: ['driver', 'workshop', 'admin'],
      default: 'driver',
    },
    authProvider: {
      type: String,
      enum: ['local', 'google'],
      default: 'local',
    },
    googleSubject: {
      type: String,
      default: null,
      index: true,
      sparse: true,
    },
    photoUrl: {
      type: String,
      default: '',
      trim: true,
    },
    profileCompleted: {
      type: Boolean,
      default: true,
    },
    accountStatus: {
      type: String,
      enum: ['pending', 'active', 'suspended', 'rejected', 'deleted'],
      default: 'active',
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
        // Backward-compatible legacy values kept for existing records.
        'not_submitted',
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
    reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    reviewedAt: { type: Date, default: null },
    rejectionReason: { type: String, default: '', trim: true },
    passwordResetTokenHash: {
      type: String,
      select: false,
      default: null,
    },
    passwordResetExpiresAt: {
      type: Date,
      select: false,
      default: null,
    },
    vehicles: {
      type: [
        {
          make: { type: String, required: true, trim: true },
          model: { type: String, required: true, trim: true },
          year: { type: String, required: true, trim: true },
          plate: { type: String, required: true, trim: true },
          color: { type: String, default: 'Custom', trim: true },
          fuel: { type: String, default: 'Gasoline', trim: true },
          mileage: { type: Number, default: 0, min: 0 },
          health: { type: Number, default: 100, min: 0, max: 100 },
        },
      ],
      default: [],
    },
    notificationTokens: {
      type: [
        {
          token: { type: String, required: true, trim: true },
          platform: {
            type: String,
            enum: ['android', 'ios', 'web', 'unknown'],
            default: 'unknown',
          },
          updatedAt: { type: Date, default: Date.now },
        },
      ],
      default: [],
      select: false,
    },
  },
  {
    timestamps: true,
  },
);

userSchema.pre('save', async function save(next) {
  if (!this.isModified('password')) {
    return next();
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

userSchema.methods.comparePassword = async function comparePassword(password) {
  return bcrypt.compare(password, this.password);
};

const User = mongoose.model('User', userSchema);

export default User;
