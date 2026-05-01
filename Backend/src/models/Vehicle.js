const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema(
  {
    ownerId:  { type: String, required: true },
    make:     String,
    model:    String,
    year:     Number,
    plate:    String,
    color:    { type: String, default: 'White' },
    fuelType: { type: String, default: 'Gasoline' },
    mileage:  { type: Number, default: 0 },
    health:   { type: Number, default: 100 },
  },
  {
    timestamps: true,
    toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } },
  },
);

module.exports = mongoose.model('Vehicle', vehicleSchema);
