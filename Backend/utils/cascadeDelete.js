import AdminWorkshopMessage from '../models/AdminWorkshopMessage.js';
import Booking from '../models/Booking.js';
import ChatMessage from '../models/ChatMessage.js';
import ChatbotMessage from '../models/ChatbotMessage.js';
import Diagnostic from '../models/Diagnostic.js';
import Notification from '../models/Notification.js';
import PackagePurchase from '../models/PackagePurchase.js';
import Vehicle from '../models/Vehicle.js';
import VerificationDocument from '../models/VerificationDocument.js';
import Workshop from '../models/Workshop.js';
import DirectMessage from '../models/DirectMessage.js';
import TrackingUpdate from '../models/TrackingUpdate.js';
import EmergencyRequest from '../models/EmergencyRequest.js';
import EmergencyMessage from '../models/EmergencyMessage.js';
import Earning from '../models/Earning.js';

export const deleteDriverRelatedData = async (userId) => {
  const bookings = await Booking.find({ user: userId }).select('_id');
  const bookingIds = bookings.map((booking) => booking._id);
  const emergencyIds = (await EmergencyRequest.find({ user: userId }).select('_id')).map((item) => item._id);
  await Promise.all([
    Vehicle.deleteMany({ owner: userId }),
    Booking.deleteMany({ user: userId }),
    ChatMessage.deleteMany({ booking: { $in: bookingIds } }),
    ChatbotMessage.deleteMany({ userId }),
    Notification.deleteMany({ user: userId }),
    Diagnostic.deleteMany({ user: userId }),
    PackagePurchase.deleteMany({ user: userId }),
    VerificationDocument.deleteMany({ owner: userId }),
    DirectMessage.deleteMany({ participants: userId }),
    TrackingUpdate.deleteMany({ booking: { $in: bookingIds } }),
    EmergencyMessage.deleteMany({ emergencyRequest: { $in: emergencyIds } }),
    EmergencyRequest.deleteMany({ user: userId }),
    Earning.deleteMany({ driver: userId }),
  ]);
};

export const deleteWorkshopRelatedData = async (workshopId, ownerId) => {
  const bookings = await Booking.find({ workshop: workshopId }).select('_id');
  const bookingIds = bookings.map((booking) => booking._id);
  const emergencyIds = (await EmergencyRequest.find({ assignedWorkshop: workshopId }).select('_id')).map((item) => item._id);
  await Promise.all([
    Booking.deleteMany({ workshop: workshopId }),
    ChatMessage.deleteMany({ booking: { $in: bookingIds } }),
    AdminWorkshopMessage.deleteMany({ workshop: workshopId }),
    VerificationDocument.deleteMany({ workshop: workshopId }),
    Notification.deleteMany({ user: ownerId }),
    Workshop.deleteOne({ _id: workshopId }),
    TrackingUpdate.deleteMany({ booking: { $in: bookingIds } }),
    EmergencyMessage.deleteMany({ emergencyRequest: { $in: emergencyIds } }),
    EmergencyRequest.deleteMany({ assignedWorkshop: workshopId }),
    Earning.deleteMany({ workshop: workshopId }),
  ]);
};
