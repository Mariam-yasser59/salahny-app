import assert from 'node:assert/strict';

import {
  classifyDocumentText,
  extractStructuredFields,
} from '../services/cvVerificationService.js';

const roleMatrix = [
  ['workshop', 'COMMERCIAL_REGISTER', true],
  ['workshop', 'TAX_CARD', false],
  ['workshop', 'DRIVING_LICENSE', false],
  ['driver', 'DRIVING_LICENSE', true],
  ['driver', 'TAX_CARD', false],
  ['driver', 'COMMERCIAL_REGISTER', false],
];

const allowed = {
  workshop: ['COMMERCIAL_REGISTER'],
  driver: ['DRIVING_LICENSE'],
};

for (const [role, documentType, expected] of roleMatrix) {
  assert.equal(
    allowed[role].includes(documentType),
    expected,
    `${role} + ${documentType} role validation mismatch`,
  );
}

assert.equal(
  classifyDocumentText('مصلحة الضرائب المصرية البطاقة الضريبية النشاط').documentType,
  'TAX_CARD',
);
assert.equal(
  classifyDocumentText('مستخرج من السجل التجاري الرقم القومي للمنشأة الاسم التجاري').documentType,
  'COMMERCIAL_REGISTER',
);
assert.equal(
  classifyDocumentText('DRIVING LICENSE Categories of Vehicle الإدارة العامة للمرور').documentType,
  'DRIVING_LICENSE',
);

const fields = extractStructuredFields(
  'DRIVING_LICENSE',
  'Name: Ahmed Ali\nLicense No: 1234567890\nExpiry: 2030-05-10\nNationality: Egyptian',
);
assert.equal(fields.fullName, 'Ahmed Ali');
assert.equal(fields.licenseNumber, '1234567890');
assert.equal(fields.expirationDate, '2030-05-10');
assert.equal(fields.nationality, 'Egyptian');

console.log('Document verification rule checks passed');
