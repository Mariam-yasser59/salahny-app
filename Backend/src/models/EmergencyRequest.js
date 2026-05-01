const mongoose = require('mongoose');

const emergencyRequestSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    location: { type: String, required: true, trim: true },
    issue: { type: String, required: true, trim: true },
    phone: { type: String, trim: true },
    notes: String,
    assignedWorkshop: { type: mongoose.Schema.Types.ObjectId, ref: 'Workshop' },
    status: { type: String, enum: ['pending', 'accepted', 'completed', 'cancelled'], default: 'pending' },
  },
  { timestamps: true, toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } } },
);

module.exports = mongoose.model('EmergencyRequest', emergencyRequestSchema);
