const rooms: Record<string, string[]> = {};

export const createRoom = (room: string, username: string): void => {
  if (!rooms[room]) {
    rooms[room] = [];
  }
  if (!rooms[room].includes(username)) {
    rooms[room].push(username);
  }
};

export const getRoomParticipants = (room: string): string[] => {
  return rooms[room] || [];
};
