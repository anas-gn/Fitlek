import { Server } from 'socket.io';

let io;

export const initSocket = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      credentials: true
    }
  });

  io.on('connection', (socket) => {
    console.log('🔗 Client connected to socket:', socket.id);

    // Client joins a specific conversation room
    socket.on('join_room', (data) => {
      if (data && data.conversationId) {
        const roomName = `conversation_${data.conversationId}`;
        socket.join(roomName);
        console.log(`Socket ${socket.id} joined room: ${roomName}`);
      }
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
