import mongoose from 'mongoose';

const directMessageSchema = new mongoose.Schema(
  {
    threadKey: { type: String, required: true, index: true },
    participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }],
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    senderRole: { type: String, enum: ['driver', 'admin'], required: true },
    text: { type: String, required: true, trim: true },
  },
  { timestamps: true },
);

directMessageSchema.index({ threadKey: 1, createdAt: 1 });

const DirectMessage = mongoose.model('DirectMessage', directMessageSchema);
export default DirectMessage;
