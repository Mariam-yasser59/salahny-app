import Diagnostic from '../models/Diagnostic.js';
import ChatbotMessage from '../models/ChatbotMessage.js';
import asyncHandler from '../utils/asyncHandler.js';
import {
  askGemini,
  currentGeminiModel,
  isGeminiConfigured,
  sanitizeGeminiError,
} from '../services/geminiService.js';

const fallbackReply = (message) =>
  isGeminiConfigured()
    ? `Gemini is temporarily unavailable, but I can still help safely. For "${message}", if the issue feels unsafe, stop the car safely and use Salahny Emergency Service. You can also run Diagnostics or find a nearby verified workshop.`
    : `I can help with that, but the live AI assistant is not configured right now. For "${message}", if the issue feels unsafe, stop the car safely and use Salahny Emergency Service. You can also run Diagnostics or find a nearby verified workshop.`;

const buildDiagnosticContext = (report) => {
  if (!report) return null;
  return {
    summary: report.summary,
    riskLevel: report.riskLevel,
    issue: report.aiPrediction?.issue,
    confidence: report.aiPrediction?.confidence,
    recommendation: report.aiPrediction?.recommendation,
    createdAt: report.createdAt,
  };
};

export const sendChatbotMessage = asyncHandler(async (req, res) => {
  const message = req.body?.message?.toString().trim() ?? '';
  if (!message) {
    return res.status(400).json({
      success: false,
      message: 'Message is required',
    });
  }
  if (message.length > 2000) {
    return res.status(413).json({
      success: false,
      message: 'Message is too long. Please keep it under 2000 characters.',
    });
  }

  const latestDiagnostic = req.user?._id
    ? await Diagnostic.findOne({ user: req.user._id }).sort({ createdAt: -1 })
    : null;

  let reply;
  let source = 'gemini';
  let geminiModel = currentGeminiModel();
  let geminiTransport = null;
  let geminiError = null;
  try {
    const geminiResult = await askGemini({
      message,
      userContext: {
        role: req.user?.role ?? 'guest',
        name: req.user?.name ?? '',
        latestDiagnostic: buildDiagnosticContext(latestDiagnostic),
      },
    });
    reply = geminiResult.reply;
    geminiModel = geminiResult.model;
    geminiTransport = geminiResult.transport;
  } catch (error) {
    geminiError = sanitizeGeminiError(error);
    if (process.env.NODE_ENV !== 'production') {
      console.error('[Gemini chatbot] request failed:', geminiError);
    }
    source = 'fallback';
    reply = fallbackReply(message);
  }

  const history = await ChatbotMessage.create({
    userId: req.user?._id ?? null,
    role: req.user?.role ?? 'guest',
    userMessage: message,
    botReply: reply,
    source,
  });

  return res.status(200).json({
    success: true,
    reply,
    data: {
      id: history._id.toString(),
      reply,
      source,
      geminiConfigured: isGeminiConfigured(),
      geminiModel,
      geminiTransport,
      ...(process.env.NODE_ENV !== 'production' || process.env.CHATBOT_DEBUG === 'true'
        ? { geminiError }
        : {}),
      diagnosticSummary: buildDiagnosticContext(latestDiagnostic),
    },
  });
});

export const getChatbotHistory = asyncHandler(async (req, res) => {
  if (!req.user?._id) {
    return res.status(200).json({ success: true, data: [] });
  }
  const messages = await ChatbotMessage.find({ userId: req.user._id })
    .sort({ createdAt: -1 })
    .limit(50);
  return res.status(200).json({
    success: true,
    data: messages.reverse().map((item) => ({
      id: item._id.toString(),
      message: item.userMessage,
      reply: item.botReply,
      source: item.source,
      createdAt: item.createdAt,
    })),
  });
});
