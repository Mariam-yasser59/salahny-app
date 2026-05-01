const mongoose = require('mongoose');

const towingRequestSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    pickupLocation: { type: String, required: true, trim: true },
    dropoffLocation: { type: String, required: true, trim: true },
    vehicleInfo: String,
    phone: String,
    price: { type: Number, default: 0 },
    status: { type: String, enum: ['pending', 'accepted', 'on_the_way', 'completed', 'cancelled'], default: 'pending' },
  },
  { timestamps: true, toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } } },
);

module.exports = mongoose.model('TowingRequest', towingRequestSchema);
