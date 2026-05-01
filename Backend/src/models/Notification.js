const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true },
    title:  String,
    body:   String,
    type:   String,
    isRead: { type: Boolean, default: false },
  },
  {
    timestamps: true,
    toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } },
  },
);

notificationSchema.index({ userId: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
