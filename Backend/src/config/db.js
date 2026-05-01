const mongoose = require('mongoose');
const dns = require('dns');

const connectDB = async () => {
  const mongoUri = process.env.MONGO_URI;

  if (!mongoUri) {
    throw new Error('MONGO_URI is not defined in environment variables');
  }

  if (process.env.DNS_SERVERS) {
    dns.setServers(process.env.DNS_SERVERS.split(',').map((server) => server.trim()));
  }

  try {
    await mongoose.connect(mongoUri, {
      serverSelectionTimeoutMS: 10000,
    });
    console.log('MongoDB Connected');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);

    if (error.code === 'ECONNREFUSED' && error.syscall === 'querySrv') {
      console.error(
        'Atlas SRV DNS lookup failed. Try DNS_SERVERS=8.8.8.8,1.1.1.1 in .env or use the non-SRV MongoDB connection string from Atlas.',
      );
    }

    throw error;
  }
};

module.exports = connectDB;
