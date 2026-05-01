require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const connectDB = require('./config/db');
const Message = require('./models/Message');
const ChatRoom = require('./models/ChatRoom');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(cors({ origin: '*', credentials: false }));
app.use(express.json());

const mountApi = (path, router) => {
  app.use(`/api${path}`, router);
  app.use(path, router);
};

mountApi('/auth', require('./routes/auth'));
mountApi('/users', require('./routes/users'));
mountApi('/vehicles', require('./routes/vehicles'));
mountApi('/workshops', require('./routes/workshops'));
mountApi('/services', require('./routes/services'));
mountApi('/packages', require('./routes/packages'));
mountApi('/bookings', require('./routes/bookings'));
mountApi('/emergency', require('./routes/emergency'));
mountApi('/towing', require('./routes/towing'));
mountApi('/car-wash', require('./routes/carWash'));
mountApi('/fuel-delivery', require('./routes/fuelDelivery'));
mountApi('/obd-prediction', require('./routes/obdPrediction'));
mountApi('/diagnostics', require('./routes/diagnostics'));
mountApi('/chat', require('./routes/chat'));
mountApi('/notifications', require('./routes/notifications'));
mountApi('/reviews', require('./routes/reviews'));
mountApi('/admin', require('./routes/admin'));

app.get('/health', (_req, res) => res.json({ status: 'ok', version: '1.0.0' }));
app.get('/api/health', (_req, res) => res.json({ status: 'ok', version: '1.0.0' }));

io.use((socket, next) => {
  try {
    const payload = jwt.verify(socket.handshake.auth.token, process.env.JWT_SECRET);
    socket.userId = payload.sub;
    next();
  } catch {
    next(new Error('Authentication error'));
  }
});

const roomId = (a, b) => [a, b].sort().join('_');

io.on('connection', (socket) => {
  socket.on('join_room', (rid) => socket.join(rid));

  socket.on('send_message', async ({ recipientId, text }) => {
    const rid = roomId(socket.userId, recipientId);
    const now = new Date();
    const msg = await Message.create({
      roomId: rid,
      senderId: socket.userId,
      recipientId,
      text,
      isRead: false,
    });

    await ChatRoom.findOneAndUpdate(
      { roomId: rid },
      { roomId: rid, participants: [socket.userId, recipientId], lastMessage: text, lastMessageAt: now },
      { upsert: true },
    );

    io.to(rid).emit('new_message', msg);
  });
});

const PORT = process.env.PORT || 5000;

server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(`[SERVER] Port ${PORT} is already in use. Stop the other process or change PORT in .env.`);
    process.exit(1);
  }

  console.error('[SERVER] Runtime error:', error);
  process.exit(1);
});

connectDB()
  .then(() => server.listen(PORT, () => console.log(`[SERVER] Running on http://localhost:${PORT}`)))
  .catch((err) => {
    console.error('[SERVER] Startup failed:', err);
    process.exit(1);
  });
