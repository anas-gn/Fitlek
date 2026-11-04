import { Server } from 'socket.io';
import {authenticateSocket, canAccessConversation, setRealtimeServer} from '../services/realtime.js';
import {createConversationActivity} from '../services/conversationActivity.js';

let io;

export const initSocket = (httpServer, db, activityOptions) => {
  io = new Server(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      credentials: true
    }
  });

  setRealtimeServer(io);
  io.use(authenticateSocket);
  const activity = createConversationActivity(io, activityOptions);
  io.on('connection', (socket) => {
    const user = socket.data.user;
    socket.join(`user_${user.id}`);
    activity(socket);
    const expiry = setTimeout(() => socket.disconnect(true), Math.max(1, user.exp * 1000 - Date.now()));
    expiry.unref();
    socket.on('disconnect', () => clearTimeout(expiry));
    console.log('🔗 Client connected to socket:', socket.id);

    // Client joins a specific conversation room
    socket.on('join_room', async (data, ack) => {
      try {
      if (data && await canAccessConversation(db, data.conversationId, user.id) && socket.connected) {
        const roomName = `conversation_${data.conversationId}`;
        socket.join(roomName);
        if (typeof ack === 'function') ack({ok:true});
        console.log(`Socket ${socket.id} joined room: ${roomName}`);
      } else if (typeof ack === 'function') ack({ok:false});
      } catch { if (typeof ack === 'function') ack({ok:false}); }
    });

    socket.on('leave_room', (data) => {
      if (data && data.conversationId) {
        const roomName = `conversation_${data.conversationId}`;
        socket.leave(roomName);
        console.log(`Socket ${socket.id} left room: ${roomName}`);
      }
    });

    socket.on('disconnect', () => {
      console.log('❌ Client disconnected:', socket.id);
    });
  });

  return io;
};

export const getIo = () => {
  if (!io) {
    throw new Error('Socket.io not initialized!');
  }
  return io;
};
