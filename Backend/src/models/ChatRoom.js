const mongoose = require('mongoose');

const chatRoomSchema = new mongoose.Schema(
  {
    roomId:        { type: String, unique: true },
    participants:  [String],
    lastMessage:   String,
    lastMessageAt: Date,
  },
  {
    timestamps: true,
    toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } },
  },
);

module.exports = mongoose.model('ChatRoom', chatRoomSchema);
