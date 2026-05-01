const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema(
  {
    userId:        String,
    packageId:     String,
    packageName:   String,
    price:         Number,
    paymentMethod: String,
    status:        { type: String, default: 'active' },
    expiresAt:     Date,
  },
  {
    timestamps: true,
    toJSON: { transform: (_, ret) => { ret.id = ret._id; delete ret._id; delete ret.__v; return ret; } },
  },
);

module.exports = mongoose.model('Subscription', subscriptionSchema);
