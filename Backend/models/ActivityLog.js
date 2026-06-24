import mongoose from 'mongoose';

const activityLogSchema = new mongoose.Schema(
  {
    actor: {
      type: String,
      required: true,
      trim: true,
    },
    actorRole: {
      type: String,
      default: 'system',
      trim: true,
    },
    action: {
      type: String,
      required: true,
      trim: true,
    },
    target: {
      type: String,
      required: true,
      trim: true,
    },
    details: {
      type: String,
      required: true,
      trim: true,
    },
  },
  {
    timestamps: true,
  },
);

const ActivityLog = mongoose.model('ActivityLog', activityLogSchema);

export default ActivityLog;
