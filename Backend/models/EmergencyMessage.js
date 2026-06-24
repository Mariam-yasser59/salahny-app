import mongoose from 'mongoose';

const emergencyMessageSchema = new mongoose.Schema(
  {
    emergencyRequest: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'EmergencyRequest',
      required: true,
    },
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    senderRole: {
      type: String,
      enum: ['driver', 'workshop', 'admin'],
      required: true,
    },
    text: { type: String, required: true, trim: true },
  },
  { timestamps: true },
);

emergencyMessageSchema.index({ emergencyRequest: 1, createdAt: 1 });
const EmergencyMessage = mongoose.model('EmergencyMessage', emergencyMessageSchema);
export default EmergencyMessage;
