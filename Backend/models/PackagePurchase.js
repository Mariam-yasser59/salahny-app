import mongoose from 'mongoose';

const packagePurchaseSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    package: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Package',
      required: true,
    },
    packageName: {
      type: String,
      required: true,
      trim: true,
    },
    amount: {
      type: Number,
      required: true,
      min: 0,
    },
    paymentMethod: {
      type: String,
      required: true,
      trim: true,
    },
    method: {
      type: String,
      default: '',
      trim: true,
    },
    currency: {
      type: String,
      default: 'EGP',
      trim: true,
      uppercase: true,
    },
    cardLast4: {
      type: String,
      default: '',
      trim: true,
      maxlength: 4,
    },
    status: {
      type: String,
      enum: ['paid', 'success', 'failed'],
      default: 'paid',
    },
    startsAt: {
      type: Date,
      required: true,
    },
    endsAt: {
      type: Date,
      required: true,
    },
    transactionRef: {
      type: String,
      required: true,
      trim: true,
    },
    transactionId: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true,
  },
);

const PackagePurchase = mongoose.model('PackagePurchase', packagePurchaseSchema);

export default PackagePurchase;
