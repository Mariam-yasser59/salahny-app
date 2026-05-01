const mongoose = require('mongoose');

const carWashRequestSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    location: { type: String, required: true, trim: true },
    packageName: { type: String, default: 'Standard' },
    scheduledAt: Date,
    phone: String,
    price: { type: Number, default: 0 },
    status: { type: String, enum: ['pending', 'accepted', 'completed', 'cancelled'], default: 'pending' },
  },
  { timestamps: true, toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } } },
);

module.exports = mongoose.model('CarWashRequest', carWashRequestSchema);
