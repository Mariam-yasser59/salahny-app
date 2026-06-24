import multer from 'multer';

import User from '../models/User.js';
import VerificationDocument from '../models/VerificationDocument.js';
import Workshop from '../models/Workshop.js';
import asyncHandler from '../utils/asyncHandler.js';
import { storeDocumentFile } from '../services/documentStorageService.js';
import { verifyDocumentWithCv } from '../services/cvVerificationService.js';

const allowedMimeTypes = ['image/jpeg', 'image/png', 'application/pdf'];

export const documentUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, cb) => {
    if (!allowedMimeTypes.includes(file.mimetype)) {
      const error = new Error('Only JPEG, PNG, and PDF files are allowed');
      error.statusCode = 400;
      return cb(error);
    }
    cb(null, true);
  },
});

const mapDocument = (document) => ({
  id: document._id.toString(),
  ownerId: document.owner?._id?.toString?.() ?? document.owner?.toString() ?? '',
  workshopId:
    document.workshop?._id?.toString?.() ?? document.workshop?.toString() ?? null,
  kind: document.kind,
  originalName: document.originalName,
  mimeType: document.mimeType,
  sizeBytes: document.sizeBytes,
  status: document.status,
  aiVerificationStatus: document.aiVerificationStatus,
  aiConfidence: document.aiConfidence,
  aiExtractedFields: document.aiExtractedFields,
  aiIssues: document.aiIssues,
  reviewedBy:
    document.reviewedBy?._id?.toString?.() ?? document.reviewedBy?.toString() ?? null,
  reviewNotes: document.reviewNotes,
  createdAt: document.createdAt,
});

const fileForDocument = async (document) => {
  if (document.data?.length) {
    return {
      buffer: document.data,
      mimetype: document.mimeType,
      originalname: document.originalName,
      size: document.sizeBytes,
    };
  }
  if (document.externalUrl) {
    const response = await fetch(document.externalUrl);
    if (!response.ok) {
      throw Object.assign(new Error('Could not read stored document file'), {
        statusCode: 502,
      });
    }
    const bytes = Buffer.from(await response.arrayBuffer());
    return {
      buffer: bytes,
      mimetype: document.mimeType,
      originalname: document.originalName,
      size: bytes.length,
    };
  }
  throw Object.assign(new Error('Stored document file is unavailable'), {
    statusCode: 409,
  });
};

const applyAiResult = async ({ document, owner, workshop, aiResult }) => {
  document.status = aiResult.status;
  document.aiVerificationStatus = aiResult.status;
  document.aiConfidence = aiResult.confidence;
  document.aiExtractedFields = aiResult.extractedFields;
  document.aiIssues = aiResult.issues;
  document.aiCheckedAt = new Date();
  await document.save();

  if (owner) {
    owner.verificationStatus = aiResult.status;
    owner.aiVerificationStatus = aiResult.status;
    owner.aiConfidence = aiResult.confidence;
    owner.aiExtractedFields = aiResult.extractedFields;
    owner.aiIssues = aiResult.issues;
    await owner.save();
  }

  if (workshop) {
    workshop.verificationStatus = aiResult.status;
    workshop.aiVerificationStatus = aiResult.status;
    workshop.aiConfidence = aiResult.confidence;
    workshop.aiExtractedFields = aiResult.extractedFields;
    workshop.aiIssues = aiResult.issues;
    await workshop.save();
  }
};

export const uploadDocument = asyncHandler(async (req, res) => {
  const { kind, workshopId } = req.body;
  if (!kind || !req.file) {
    return res.status(400).json({
      success: false,
      message: 'kind and file are required',
    });
  }

  if (req.user.role === 'driver' && kind !== 'driver_license') {
    return res.status(400).json({
      success: false,
      message: 'Drivers can upload only driver licenses',
    });
  }

  if (
    req.user.role === 'workshop' &&
    !['business_license', 'commercial_registration', 'permit'].includes(kind)
  ) {
    return res.status(400).json({
      success: false,
      message: 'Invalid workshop verification document type',
    });
  }

  let workshop = null;
  if (req.user.role === 'workshop') {
    workshop = await Workshop.findOne({ owner: req.user._id });
    if (!workshop) {
      return res.status(404).json({
        success: false,
        message: 'Create a workshop profile before uploading workshop documents',
      });
    }
  } else if (req.user.role === 'admin' && workshopId) {
    workshop = await Workshop.findById(workshopId);
  }

  const storedFile = await storeDocumentFile(req.file);
  const document = await VerificationDocument.create({
    owner: req.user._id,
    workshop: workshop?._id ?? null,
    kind,
    originalName: req.file.originalname,
    mimeType: req.file.mimetype,
    sizeBytes: req.file.size,
    data: storedFile.data,
    storageProvider: storedFile.storageProvider,
    externalUrl: storedFile.externalUrl,
    storageKey: storedFile.storageKey,
    status: 'ai_processing',
    aiVerificationStatus: 'ai_processing',
  });

  req.user.verificationStatus = 'ai_processing';
  req.user.aiVerificationStatus = 'ai_processing';
  await req.user.save();
  if (workshop) {
    workshop.accountStatus = 'pending';
    workshop.isVerified = false;
    workshop.verificationStatus = 'ai_processing';
    workshop.aiVerificationStatus = 'ai_processing';
    await workshop.save();
  }

  const aiResult = await verifyDocumentWithCv({
    file: req.file,
    role: req.user.role === 'workshop' ? 'workshop' : 'driver',
    documentType: kind === 'permit' ? 'workshop_permit' : kind,
  });
  await applyAiResult({ document, owner: req.user, workshop, aiResult });

  res.status(201).json({ success: true, data: mapDocument(document) });
});

export const reverifyDocument = asyncHandler(async (req, res) => {
  const document = await VerificationDocument.findById(req.params.id).select('+data');
  if (!document) {
    return res.status(404).json({ success: false, message: 'Document not found' });
  }

  const canReverify =
    req.user.role === 'admin' || document.owner.toString() === req.user._id.toString();
  if (!canReverify) {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }

  const owner = await User.findById(document.owner);
  if (!owner) {
    return res.status(404).json({ success: false, message: 'Document owner not found' });
  }
  const workshop = document.workshop ? await Workshop.findById(document.workshop) : null;
  const file = await fileForDocument(document);
  const aiResult = await verifyDocumentWithCv({
    file,
    role: owner.role === 'workshop' ? 'workshop' : 'driver',
    documentType: document.kind === 'permit' ? 'workshop_permit' : document.kind,
  });

  await applyAiResult({ document, owner, workshop, aiResult });
  res.status(200).json({ success: true, data: mapDocument(document) });
});

export const getMyDocuments = asyncHandler(async (req, res) => {
  const documents = await VerificationDocument.find({ owner: req.user._id }).sort({
    createdAt: -1,
  });
  res.status(200).json({
    success: true,
    data: documents.map(mapDocument),
  });
});

export const getDocumentFile = asyncHandler(async (req, res) => {
  const document = await VerificationDocument.findById(req.params.id).select('+data');
  if (!document) {
    return res.status(404).json({ success: false, message: 'Document not found' });
  }

  const canRead =
    req.user.role === 'admin' || document.owner.toString() === req.user._id.toString();
  if (!canRead) {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }

  res.setHeader('Content-Type', document.mimeType);
  res.setHeader('Content-Length', document.sizeBytes);
  res.setHeader('Content-Disposition', `inline; filename="${document.originalName}"`);
  if (document.storageProvider === 'cloudinary' && document.externalUrl) {
    return res.redirect(document.externalUrl);
  }
  res.status(200).send(document.data);
});
