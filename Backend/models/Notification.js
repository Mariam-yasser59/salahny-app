import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      alias: 'recipient',
      default: null,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    body: {
      type: String,
      required: true,
      alias: 'message',
      trim: true,
    },
    type: {
      type: String,
      enum: ['booking', 'reminder', 'promo', 'diagnostic', 'ai_report', 'chat', 'emergency', 'system'],
      default: 'system',
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    isGlobal: {
      type: Boolean,
      default: false,
    },
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    relatedEntityId: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true,
  },
);

const Notification = mongoose.model('Notification', notificationSchema);

export default Notification;
