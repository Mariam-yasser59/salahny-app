import dotenv from 'dotenv';
import mongoose from 'mongoose';

import connectDB from '../config/db.js';

dotenv.config();

try {
  await connectDB();
  await mongoose.connection.db.admin().ping();
  console.log('MongoDB ping successful');
  await mongoose.disconnect();
  process.exit(0);
} catch (error) {
  console.error('MongoDB ping failed:', error.message);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
}
