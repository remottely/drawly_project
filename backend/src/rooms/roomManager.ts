const rooms: Record<string, string[]> = {};

// Cria uma sala ou adiciona um participante a uma sala existente
export const createRoom = (room: string, username: string): void => {
  if (!rooms[room]) {
    rooms[room] = [];
  }
  if (!rooms[room].includes(username)) {
    rooms[room].push(username);
  }
};

// Remove um participante de uma sala
export const removeParticipant = (room: string, username: string): void => {
  if (!rooms[room]) return;
  rooms[room] = rooms[room].filter((user) => user !== username);
  if (rooms[room].length === 0) {
    delete rooms[room];
  }
};

// Retorna os participantes de uma sala
export const getRoomParticipants = (room: string): string[] => {
  return rooms[room] || [];
};
