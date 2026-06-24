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
      enum: [
        'pending',
        'accepted',
        'in_progress',
        'diagnostics_ready',
        'repair_in_progress',
        'rejected',
        'completed',
        'cancelled',
      ],
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
    vehicleId: {
      type: String,
      default: '',
      trim: true,
    },
    address: {
      type: String,
      default: '',
      trim: true,
    },
    latitude: {
      type: Number,
      default: null,
    },
    longitude: {
      type: Number,
      default: null,
    },
    locationNotes: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true,
  },
);

bookingSchema.index(
  { workshop: 1, date: 1 },
  {
    unique: true,
    partialFilterExpression: {
      status: { $in: ['pending', 'accepted'] },
    },
  },
);
bookingSchema.index({ user: 1, createdAt: -1 });

const Booking = mongoose.model('Booking', bookingSchema);

export default Booking;
