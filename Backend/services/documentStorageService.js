import crypto from 'crypto';

export const storeDocumentFile = async (file) => {
  if (
    process.env.DOCUMENT_STORAGE_PROVIDER !== 'cloudinary' ||
    !process.env.CLOUDINARY_CLOUD_NAME ||
    !process.env.CLOUDINARY_API_KEY ||
    !process.env.CLOUDINARY_API_SECRET
  ) {
    return {
      storageProvider: 'mongodb',
      data: file.buffer,
      externalUrl: null,
      storageKey: null,
    };
  }

  const timestamp = Math.floor(Date.now() / 1000);
  const folder = process.env.CLOUDINARY_DOCUMENT_FOLDER || 'salahny-documents';
  const paramsToSign = `folder=${folder}&timestamp=${timestamp}${process.env.CLOUDINARY_API_SECRET}`;
  const signature = crypto.createHash('sha1').update(paramsToSign).digest('hex');
  const body = new FormData();
  body.append('file', new Blob([file.buffer], { type: file.mimetype }), file.originalname);
  body.append('api_key', process.env.CLOUDINARY_API_KEY);
  body.append('timestamp', String(timestamp));
  body.append('folder', folder);
  body.append('signature', signature);

  try {
    const response = await fetch(
      `https://api.cloudinary.com/v1_1/${process.env.CLOUDINARY_CLOUD_NAME}/auto/upload`,
      { method: 'POST', body },
    );
    if (!response.ok) {
      throw new Error('Cloud document upload failed');
    }
    const uploaded = await response.json();
    return {
      storageProvider: 'cloudinary',
      data: undefined,
      externalUrl: uploaded.secure_url,
      storageKey: uploaded.public_id,
    };
  } catch {
    return {
      storageProvider: 'mongodb',
      data: file.buffer,
      externalUrl: null,
      storageKey: null,
    };
  }
};
