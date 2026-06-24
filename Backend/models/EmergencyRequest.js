import mongoose from 'mongoose';

const emergencyRequestSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    vehicle: { type: mongoose.Schema.Types.ObjectId, ref: 'Vehicle', default: null },
    emergencyType: {
      type: String,
      enum: ['towing', 'battery', 'tire', 'engine', 'fuel', 'lockout', 'other'],
      default: 'other',
    },
    issueDescription: { type: String, required: true, trim: true },
    address: { type: String, required: true, trim: true },
    latitude: { type: Number, default: null },
    longitude: { type: Number, default: null },
    locationNotes: { type: String, default: '', trim: true },
    phone: { type: String, default: '', trim: true },
    vehicleLabel: { type: String, default: '', trim: true },
    assignedWorkshop: { type: mongoose.Schema.Types.ObjectId, ref: 'Workshop', default: null },
    assignedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    assignmentMethod: {
      type: String,
      enum: ['ai_nearest_match', 'admin_manual', 'unassigned'],
      default: 'unassigned',
    },
    distanceKm: { type: Number, default: null },
    status: {
      type: String,
      enum: [
        'pending',
        'pending_admin_assignment',
        'assigned',
        'accepted_by_workshop',
        'mechanic_on_the_way',
        'arrived',
        'in_progress',
        'completed',
        'cancelled',
        'rejected',
      ],
      default: 'pending',
    },
    statusHistory: {
      type: [
        {
          status: { type: String, required: true },
          changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
          note: { type: String, default: '' },
          changedAt: { type: Date, default: Date.now },
        },
      ],
      default: [],
    },
    completedAt: { type: Date, default: null },
    cancelledReason: { type: String, default: '', trim: true },
  },
  { timestamps: true },
);

emergencyRequestSchema.index({ user: 1, createdAt: -1 });
emergencyRequestSchema.index({ assignedWorkshop: 1, status: 1 });
emergencyRequestSchema.index({ status: 1, createdAt: -1 });

const EmergencyRequest = mongoose.model('EmergencyRequest', emergencyRequestSchema);
export default EmergencyRequest;
