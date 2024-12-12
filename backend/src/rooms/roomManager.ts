interface Room {
  name: string;
  participants: string[];
}

const rooms: Room[] = [];

export const createRoom = (roomName: string, username: string): void => {
  const existingRoom = rooms.find((room) => room.name === roomName);

  if (existingRoom) {
    if (!existingRoom.participants.includes(username)) {
      existingRoom.participants.push(username);
    }
  } else {
    rooms.push({ name: roomName, participants: [username] });
  }
};

export const removeParticipant = (roomName: string, username: string, availableRooms: Set<string>): void => {
  const roomIndex = rooms.findIndex((room) => room.name === roomName);

  if (roomIndex !== -1) {
    const room = rooms[roomIndex];
    room.participants = room.participants.filter((user) => user !== username);

    if (room.participants.length === 0) {
      rooms.splice(roomIndex, 1);
      availableRooms.delete(roomName);
    }
  }
};

export const getRoomParticipants = (roomName: string): string[] => {
  const room = rooms.find((room) => room.name === roomName);
  return room?.participants || [];
};