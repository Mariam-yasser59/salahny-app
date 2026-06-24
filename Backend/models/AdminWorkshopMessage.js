import mongoose from 'mongoose';

const adminWorkshopMessageSchema = new mongoose.Schema(
  {
    workshop: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Workshop',
      required: true,
      index: true,
    },
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    senderRole: {
      type: String,
      enum: ['admin', 'workshop'],
      required: true,
    },
    text: {
      type: String,
      required: true,
      trim: true,
    },
    readByAdmin: {
      type: Boolean,
      default: false,
    },
    readByWorkshop: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  },
);

const AdminWorkshopMessage = mongoose.model(
  'AdminWorkshopMessage',
  adminWorkshopMessageSchema,
);

export default AdminWorkshopMessage;
