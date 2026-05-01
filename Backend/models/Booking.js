import mongoose from 'mongoose';

const bookingSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    workshop: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Workshop',
      required: true,
    },
    service: {
      type: String,
      required: true,
      trim: true,
    },
    serviceId: {
      type: String,
      trim: true,
      default: '',
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected', 'completed', 'cancelled'],
      default: 'pending',
    },
    date: {
      type: Date,
      required: true,
    },
    paymentMethod: {
      type: String,
      default: 'Cash on Service',
      trim: true,
    },
    total: {
      type: Number,
      default: 0,
      min: 0,
    },
    vehicleLabel: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true,
  },
);

const Booking = mongoose.model('Booking', bookingSchema);

export default Booking;
