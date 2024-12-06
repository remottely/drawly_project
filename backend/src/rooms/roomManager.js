const rooms = {};

const createRoom = (room, username) => {
  if (!rooms[room]) {
    rooms[room] = [];
  }
  if (!rooms[room].includes(username)) {
    rooms[room].push(username);
  }
};

const getRoomParticipants = (room) => {
  return rooms[room] || [];
};

module.exports = {
  createRoom,
  getRoomParticipants,
};
