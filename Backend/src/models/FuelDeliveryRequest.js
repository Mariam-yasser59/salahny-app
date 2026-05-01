const mongoose = require('mongoose');

const fuelDeliveryRequestSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    location: { type: String, required: true, trim: true },
    fuelType: { type: String, enum: ['gasoline', 'diesel', 'electric'], default: 'gasoline' },
    liters: { type: Number, required: true, min: 1 },
    phone: String,
    price: { type: Number, default: 0 },
    status: { type: String, enum: ['pending', 'accepted', 'delivered', 'cancelled'], default: 'pending' },
  },
  { timestamps: true, toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } } },
);

module.exports = mongoose.model('FuelDeliveryRequest', fuelDeliveryRequestSchema);
