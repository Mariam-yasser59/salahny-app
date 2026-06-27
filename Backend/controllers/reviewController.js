import Booking from '../models/Booking.js';
import Review from '../models/Review.js';
import User from '../models/User.js';
import Workshop from '../models/Workshop.js';
import asyncHandler from '../utils/asyncHandler.js';
import { createNotification } from './notificationController.js';

const roundedRating = (value) => Math.round(value * 10) / 10;

const updateWorkshopRating = async (workshopId) => {
  const aggregate = await Review.aggregate([
    { $match: { reviewee: workshopId, revieweeModel: 'Workshop' } },
    { $group: { _id: '$reviewee', rating: { $avg: '$rating' }, count: { $sum: 1 } } },
  ]);
  const stats = aggregate[0] || { rating: 0, count: 0 };
  await Workshop.findByIdAndUpdate(workshopId, {
    rating: stats.count ? roundedRating(stats.rating) : 0,
    reviewCount: stats.count,
  });
};

const updateDriverRating = async (driverId) => {
  const aggregate = await Review.aggregate([
    { $match: { reviewee: driverId, revieweeModel: 'User' } },
    { $group: { _id: '$reviewee', rating: { $avg: '$rating' }, count: { $sum: 1 } } },
  ]);
  const stats = aggregate[0] || { rating: 0, count: 0 };
  await User.findByIdAndUpdate(driverId, {
    rating: stats.count ? roundedRating(stats.rating) : 0,
    reviewCount: stats.count,
  });
};

const parseRating = (value) => {
  const rating = Number(value);
  return Number.isFinite(rating) ? rating : null;
};

export const createReview = asyncHandler(async (req, res) => {
  const { bookingId, rating: rawRating, comment = '' } = req.body;
  const rating = parseRating(rawRating);

  if (!bookingId || rating === null || rating < 1 || rating > 5) {
    return res.status(400).json({
      success: false,
      message: 'bookingId and a rating from 1 to 5 are required',
    });
  }

  if (!['driver', 'workshop'].includes(req.user.role)) {
    return res.status(403).json({
      success: false,
      message: 'Only drivers and workshops can submit service ratings',
    });
  }

  const booking = await Booking.findById(bookingId)
    .populate('workshop', 'owner name')
    .populate('user', 'name');

  if (!booking) {
    return res.status(404).json({ success: false, message: 'Booking not found' });
  }

  if (booking.status !== 'completed') {
    return res.status(409).json({
      success: false,
      message: 'Ratings can be submitted only after the request is completed',
    });
  }

  const isDriver =
    req.user.role === 'driver' &&
    booking.user?._id?.toString() === req.user._id.toString();
  const isWorkshop =
    req.user.role === 'workshop' &&
    booking.workshop?.owner?.toString() === req.user._id.toString();

  if (!isDriver && !isWorkshop) {
    return res.status(403).json({
      success: false,
      message: 'You can rate only your own completed request',
    });
  }

  const reviewee = isDriver ? booking.workshop._id : booking.user._id;
  const revieweeModel = isDriver ? 'Workshop' : 'User';
  const reviewerRole = isDriver ? 'driver' : 'workshop';

  try {
    const review = await Review.create({
      booking: booking._id,
      reviewer: req.user._id,
      reviewerRole,
      reviewee,
      revieweeModel,
      rating,
      comment: comment.toString().trim(),
    });

    if (isDriver) {
      await updateWorkshopRating(booking.workshop._id);
      if (booking.workshop.owner) {
        await createNotification({
          userId: booking.workshop.owner,
          title: 'New workshop rating',
          body: `${booking.user.name} rated ${booking.service} ${rating.toFixed(1)} stars.`,
          type: 'system',
          data: { bookingId: booking._id.toString(), rating },
        });
      }
    } else {
      await updateDriverRating(booking.user._id);
      await createNotification({
        userId: booking.user._id,
        title: 'New driver rating',
        body: `${booking.workshop.name} rated your completed request ${rating.toFixed(1)} stars.`,
        type: 'system',
        data: { bookingId: booking._id.toString(), rating },
      });
    }

    res.status(201).json({
      success: true,
      message: 'Rating submitted successfully',
      data: review,
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'You already rated this completed request',
      });
    }
    throw error;
  }
});

export const getBookingReviews = asyncHandler(async (req, res) => {
  const booking = await Booking.findById(req.params.bookingId)
    .populate('workshop', 'owner')
    .select('user workshop');

  if (!booking) {
    return res.status(404).json({ success: false, message: 'Booking not found' });
  }

  const canView =
    req.user.role === 'admin' ||
    booking.user.toString() === req.user._id.toString() ||
    booking.workshop?.owner?.toString() === req.user._id.toString();

  if (!canView) {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }

  const reviews = await Review.find({ booking: booking._id }).sort({ createdAt: -1 });
  res.status(200).json({ success: true, data: reviews });
});
