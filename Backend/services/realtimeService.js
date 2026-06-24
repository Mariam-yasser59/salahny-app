import jwt from 'jsonwebtoken';
import { Server } from 'socket.io';

import Booking from '../models/Booking.js';
import Workshop from '../models/Workshop.js';
import User from '../models/User.js';

let io = null;

const bookingRoom = (bookingId) => `booking:${bookingId}`;
const userRoom = (userId) => `user:${userId}`;
const workshopRoom = (workshopId) => `workshop:${workshopId}`;

const canAccessBooking = async (bookingId, user) => {
  const booking = await Booking.findById(bookingId).populate('workshop', 'owner');
  if (!booking) return false;
  return (
    user.role === 'admin' ||
    booking.user.toString() === user._id.toString() ||
    booking.workshop?.owner?.toString() === user._id.toString()
  );
};

export const initRealtime = (server) => {
  io = new Server(server, { cors: { origin: true, credentials: true } });

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (!token) return next(new Error('No token provided'));
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id);
      if (!user || user.accountStatus === 'deleted') {
        return next(new Error('User unavailable'));
      }
      socket.data.user = user;
      return next();
    } catch (_error) {
      return next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    const user = socket.data.user;
    socket.join(userRoom(user._id.toString()));

    socket.on('join_booking', async ({ bookingId } = {}, acknowledge) => {
      const allowed = bookingId && (await canAccessBooking(bookingId, user));
      if (allowed) socket.join(bookingRoom(bookingId));
      acknowledge?.({ ok: Boolean(allowed) });
    });

    socket.on('join_workshop_admin', async ({ workshopId } = {}, acknowledge) => {
      let workshop = null;
      if (user.role === 'admin' && workshopId) {
        workshop = await Workshop.findById(workshopId);
      } else if (user.role === 'workshop') {
        workshop = await Workshop.findOne({ owner: user._id });
      }
      if (workshop) socket.join(workshopRoom(workshop._id.toString()));
      acknowledge?.({ ok: Boolean(workshop) });
    });
  });
};

export const emitBookingMessage = (bookingId, payload) => {
  io?.to(bookingRoom(bookingId)).emit('booking_message', payload);
};

export const emitTrackingUpdate = (bookingId, payload) => {
  io?.to(bookingRoom(bookingId)).emit('tracking_update', payload);
};

export const emitUserMessage = (userId, payload) => {
  io?.to(userRoom(userId.toString())).emit('direct_message', payload);
};

export const emitNotification = (userId, payload) => {
  io?.to(userRoom(userId.toString())).emit('notification_created', payload);
};

export const emitWorkshopAdminMessage = (workshopId, payload) => {
  io?.to(workshopRoom(workshopId.toString())).emit('workshop_admin_message', payload);
};
