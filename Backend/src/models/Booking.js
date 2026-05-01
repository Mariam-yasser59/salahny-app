const mongoose = require('mongoose');

const STATUSES = [
  'pending',
  'accepted',
  'rejected',
  'in_progress',
  'diagnostics_ready',
  'repair_in_progress',
  'completed',
  'cancelled',
];

const bookingSchema = new mongoose.Schema(
  {
    user:        { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    workshop:    { type: mongoose.Schema.Types.ObjectId, ref: 'Workshop' },
    service:     { type: String, trim: true },
    date:        { type: Date, default: Date.now },
    driverId:    String,
    driverName:  String,
    driverPhone: String,
    workshopId:  String,
    workshopName:String,
    vehicleId:   String,
    vehicleInfo: String,
    serviceName: String,
    time:        String,
    notes:       String,
    price:       { type: Number, default: 0 },
    status:      { type: String, enum: STATUSES, default: 'pending' },
    progress:    { type: Number, default: 0 },
    statusNotes: String,
  },
  {
    timestamps: true,
    toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } },
  },
);

module.exports = mongoose.model('Booking', bookingSchema);
