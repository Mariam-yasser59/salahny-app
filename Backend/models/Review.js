import mongoose from 'mongoose';

const reviewSchema = new mongoose.Schema(
  {
    booking: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
      required: true,
    },
    reviewer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    reviewerRole: {
      type: String,
      enum: ['driver', 'workshop'],
      required: true,
    },
    reviewee: {
      type: mongoose.Schema.Types.ObjectId,
      refPath: 'revieweeModel',
      required: true,
    },
    revieweeModel: {
      type: String,
      enum: ['User', 'Workshop'],
      required: true,
    },
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
    },
    comment: {
      type: String,
      default: '',
      trim: true,
      maxlength: 500,
    },
  },
  { timestamps: true },
);

reviewSchema.index({ booking: 1, reviewerRole: 1 }, { unique: true });
reviewSchema.index({ reviewee: 1, revieweeModel: 1, createdAt: -1 });

const Review = mongoose.model('Review', reviewSchema);
export default Review;
