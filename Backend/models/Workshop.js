import mongoose from 'mongoose';

const workshopSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    location: {
      type: String,
      required: true,
      trim: true,
    },
    services: {
      type: [String],
      default: [],
    },
    prices: {
      type: Map,
      of: Number,
      default: {},
    },
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    rating: {
      type: Number,
      default: 4.8,
      min: 0,
      max: 5,
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    accountStatus: {
      type: String,
      enum: ['pending', 'active', 'suspended', 'rejected', 'deleted'],
      default: 'active',
    },
  },
  {
    timestamps: true,
  },
);

const Workshop = mongoose.model('Workshop', workshopSchema);

export default Workshop;
