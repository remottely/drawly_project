"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRoomParticipants = exports.removeParticipant = exports.createRoom = void 0;
const rooms = [];
const createRoom = (roomName, username) => {
    const existingRoom = rooms.find((room) => room.name === roomName);
    if (existingRoom) {
        if (!existingRoom.participants.includes(username)) {
            existingRoom.participants.push(username);
        }
    }
    else {
        rooms.push({ name: roomName, participants: [username] });
    }
};
exports.createRoom = createRoom;
const removeParticipant = (roomName, username, availableRooms) => {
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
exports.removeParticipant = removeParticipant;
const getRoomParticipants = (roomName) => {
    const room = rooms.find((room) => room.name === roomName);
    return (room === null || room === void 0 ? void 0 : room.participants) || [];
};
exports.getRoomParticipants = getRoomParticipants;
