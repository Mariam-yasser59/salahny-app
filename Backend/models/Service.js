import mongoose from 'mongoose';

const serviceSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    category: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
    },
    emoji: {
      type: String,
      default: '🔧',
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    durationMins: {
      type: Number,
      default: 60,
      min: 1,
    },
    isPopular: {
      type: Boolean,
      default: false,
    },
    isEnabled: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  },
);

const Service = mongoose.model('Service', serviceSchema);

export default Service;
