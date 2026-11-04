// Ephemeral presence only: never store drafts or recording contents.
export function createConversationActivity(io, {ttlMs = 7000} = {}) {
  const rooms = new Map();
  const aggregate = (members, userID) => {
    const states = [...members.values()].filter(s => s.userID === userID).map(s => s.activity);
    return states.includes('recording') ? 'recording' : states.includes('typing') ? 'typing' : 'idle';
  };
  const publish = (room, userID) => io.to(`conversation_${room}`).emit('conversation_activity', {
    conversationID: Number(room), userID: Number(userID),
    activity: aggregate(rooms.get(room) ?? new Map(), userID), expiresInMs: ttlMs
  });
  const clear = (socket, room) => {
    const members = rooms.get(room);
    const state = members?.get(socket.id);
    if (!state) return;
    clearTimeout(state.timer);
    members.delete(socket.id);
    if (!members.size) rooms.delete(room);
    publish(room, state.userID);
  };
  const attach = socket => {
    socket.on('conversation_activity', data => {
      if (!data || !/^[1-9]\d*$/.test(String(data.conversationID))) return;
      const room = String(data.conversationID);
      if (!socket.rooms.has(`conversation_${room}`) || !['typing','recording','idle'].includes(data.activity)) return;
      if (data.activity === 'idle') { clear(socket, room); return; }
      const members = rooms.get(room) ?? new Map();
      const previous = members.get(socket.id);
      const now = Date.now();
      // Heartbeats need not run more often than once a second.
      if (previous && previous.activity === data.activity && now - previous.updatedAt < 1000) return;
      if (previous) clearTimeout(previous.timer);
      const state = {userID: socket.data.user.id, activity: data.activity, updatedAt: now};
      state.timer = setTimeout(() => clear(socket, room), ttlMs);
      state.timer.unref();
      members.set(socket.id, state);
      rooms.set(room, members);
      publish(room, state.userID);
    });
    socket.on('leave_room', data => { if (data?.conversationId) clear(socket, String(data.conversationId)); });
    socket.on('disconnect', () => {
      for (const room of [...rooms.keys()]) clear(socket, room);
    });
  };
  return attach;
}
