"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRoomParticipants = exports.removeParticipant = exports.createRoom = void 0;
const rooms = {};
// Cria uma sala ou adiciona um participante a uma sala existente
const createRoom = (room, username) => {
    if (!rooms[room]) {
        rooms[room] = [];
    }
    if (!rooms[room].includes(username)) {
        rooms[room].push(username);
    }
};
exports.createRoom = createRoom;
const removeParticipant = (room, username, availableRooms) => {
    console.log(`Attempting to remove participant ${username} from room ${room}`);
    // Verifica se a sala existe
    if (!rooms[room]) {
        console.warn(`Room ${room} does not exist. Cannot remove participant ${username}.`);
        return;
    }
    // Remove o usuário da sala
    const initialCount = rooms[room].length;
    rooms[room] = rooms[room].filter((user) => user !== username);
    if (rooms[room].length < initialCount) {
        console.log(`Participant ${username} removed from room ${room}`);
    }
    else {
        console.warn(`Participant ${username} was not found in room ${room}`);
    }
    // Remove a sala se ela estiver vazia
    if (rooms[room].length === 0) {
        delete rooms[room];
        console.log(`Room ${room} is empty and has been removed.`);
        availableRooms.delete(room); // Atualiza as salas disponíveis
    }
    else {
        console.log(`Updated participants in room ${room}:`, rooms[room]);
    }
};
exports.removeParticipant = removeParticipant;
// Retorna os participantes de uma sala
const getRoomParticipants = (room) => {
    return rooms[room] || [];
};
exports.getRoomParticipants = getRoomParticipants;
