"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRoomParticipants = exports.createRoom = void 0;
const rooms = {};
const createRoom = (room, username) => {
    if (!rooms[room]) {
        rooms[room] = [];
    }
    if (!rooms[room].includes(username)) {
        rooms[room].push(username);
    }
};
exports.createRoom = createRoom;
const getRoomParticipants = (room) => {
    return rooms[room] || [];
};
exports.getRoomParticipants = getRoomParticipants;
