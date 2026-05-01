const mongoose = require('mongoose');

const driverProfileSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    phone: { type: String, trim: true },
    address: { type: String, trim: true },
    licenseNumber: { type: String, trim: true },
    vehicles: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Vehicle' }],
    emergencyContact: {
      name: String,
      phone: String,
    },
    status: { type: String, enum: ['active', 'inactive', 'blocked'], default: 'active' },
  },
  { timestamps: true, toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } } },
);

module.exports = mongoose.model('DriverProfile', driverProfileSchema);
