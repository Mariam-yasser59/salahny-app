import mongoose from 'mongoose';

const vehicleSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    make: { type: String, required: true, trim: true },
    model: { type: String, required: true, trim: true },
    year: { type: String, required: true, trim: true },
    plate: { type: String, required: true, trim: true },
    color: { type: String, default: 'White', trim: true },
    fuel: { type: String, default: 'Gasoline', trim: true },
    mileage: { type: Number, default: 0 },
    health: { type: Number, default: 100 },
  },
  { timestamps: true },
);

vehicleSchema.index({ owner: 1, plate: 1 }, { unique: true });

const Vehicle = mongoose.model('Vehicle', vehicleSchema);
export default Vehicle;
