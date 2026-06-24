import mongoose from 'mongoose';

const earningSchema = new mongoose.Schema(
  {
    workshop: { type: mongoose.Schema.Types.ObjectId, ref: 'Workshop', required: true },
    booking: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
      required: true,
      unique: true,
    },
    driver: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    serviceId: { type: String, default: '', trim: true },
    amount: { type: Number, required: true, min: 0 },
    status: {
      type: String,
      enum: ['earned', 'pending_payout', 'paid'],
      default: 'earned',
    },
  },
  { timestamps: true },
);

earningSchema.index({ workshop: 1, createdAt: -1 });
const Earning = mongoose.model('Earning', earningSchema);
export default Earning;
