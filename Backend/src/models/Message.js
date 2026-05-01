const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    roomId:     { type: String, required: true },
    senderId:   String,
    senderName: String,
    recipientId:String,
    text:       String,
    isRead:     { type: Boolean, default: false },
  },
  {
    timestamps: true,
    toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } },
  },
);

messageSchema.index({ roomId: 1, createdAt: 1 });

module.exports = mongoose.model('Message', messageSchema);
