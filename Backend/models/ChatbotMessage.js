import mongoose from 'mongoose';

const chatbotMessageSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    role: {
      type: String,
      enum: ['driver', 'workshop', 'admin', 'guest'],
      default: 'guest',
      index: true,
    },
    userMessage: {
      type: String,
      required: true,
      trim: true,
      maxlength: 2000,
    },
    botReply: {
      type: String,
      required: true,
      trim: true,
      maxlength: 6000,
    },
    source: {
      type: String,
      enum: ['gemini', 'fallback'],
      default: 'gemini',
    },
  },
  {
    timestamps: true,
  },
);

const ChatbotMessage = mongoose.model('ChatbotMessage', chatbotMessageSchema);

export default ChatbotMessage;
