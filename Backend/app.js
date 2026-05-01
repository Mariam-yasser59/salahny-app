import cors from 'cors';
import express from 'express';
import morgan from 'morgan';

import authRoutes from './routes/authRoutes.js';
import adminRoutes from './routes/adminRoutes.js';
import bookingRoutes from './routes/bookingRoutes.js';
import catalogRoutes from './routes/catalogRoutes.js';
import chatRoutes from './routes/chatRoutes.js';
import contentRoutes from './routes/contentRoutes.js';
import diagnosticRoutes from './routes/diagnosticRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import userRoutes from './routes/userRoutes.js';
import workshopPortalRoutes from './routes/workshopPortalRoutes.js';
import workshopRoutes from './routes/workshopRoutes.js';
import { errorHandler, notFound } from './middleware/errorMiddleware.js';

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

app.get('/api/health', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'Salahny API is running',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/content', contentRoutes);
app.use('/api/users', userRoutes);
app.use('/api/workshops', workshopRoutes);
app.use('/api/workshop-portal', workshopPortalRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/diagnostics', diagnosticRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api', catalogRoutes);

app.use(notFound);
app.use(errorHandler);

export default app;
