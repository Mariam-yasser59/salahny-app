const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name:         { type: String, required: true, trim: true },
    email:        { type: String, required: true, unique: true, lowercase: true, trim: true },
    phone:        String,
    password:     { type: String, required: true, select: false },
    role:         { type: String, enum: ['driver', 'workshop', 'admin'], default: 'driver' },
    walletBalance: { type: Number, default: 0 },
    rating:       { type: Number, default: 0 },
    totalBookings:{ type: Number, default: 0 },
    isActive:     { type: Boolean, default: true },
    isVerified:   { type: Boolean, default: false },
    // Workshop-only fields
    workshopName: String,
    address:      String,
    specialty:    String,
    isOpen:       { type: Boolean, default: true },
    jobsDone:     { type: Number, default: 0 },
    reviewCount:  { type: Number, default: 0 },
    services:     [String],
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_, ret) => {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        delete ret.password;
        return ret;
      },
    },
  },
);

userSchema.pre('save', async function hashPassword() {
  if (this.isModified('password')) {
    this.password = await bcrypt.hash(this.password, 10);
  }
});

userSchema.methods.comparePassword = function comparePassword(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
