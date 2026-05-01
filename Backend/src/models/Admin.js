const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    permissions: { type: [String], default: ['all'] },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  },
  { timestamps: true, toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } } },
);

module.exports = mongoose.model('Admin', adminSchema);
