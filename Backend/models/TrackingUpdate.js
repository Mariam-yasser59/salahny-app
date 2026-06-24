import mongoose from 'mongoose';

const trackingUpdateSchema = new mongoose.Schema(
  {
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true, index: true },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    etaMinutes: { type: Number, min: 0, default: 0 },
    note: { type: String, default: '', trim: true },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: true },
);

trackingUpdateSchema.index({ booking: 1, createdAt: -1 });

const TrackingUpdate = mongoose.model('TrackingUpdate', trackingUpdateSchema);
export default TrackingUpdate;
