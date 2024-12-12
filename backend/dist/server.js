"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const express_1 = __importDefault(require("express"));
const http_1 = __importDefault(require("http"));
const socket_io_1 = require("socket.io");
dotenv_1.default.config();
// Setup
const app = (0, express_1.default)();
const server = http_1.default.createServer(app);
const io = new socket_io_1.Server(server, {
    cors: { origin: "*" }, // Permitir conexões de qualquer origem
});
const PORT = process.env.PORT || 5555;
// Middleware
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Objects
class Stroke {
    constructor(points, color, size, opacity, strokeType, filled) {
        this.points = points;
        this.color = color;
        this.size = size;
        this.opacity = opacity;
        this.strokeType = strokeType;
        this.filled = filled;
    }
}
class RoomDrawing {
    constructor() {
        this.strokes = [];
        this.backupStrokes = [];
    }
    addStrokes(newStrokes) {
        this.strokes.push(...newStrokes);
    }
    clear() {
        this.strokes = [];
        this.backupStrokes = [];
    }
    undo() {
        const lastStroke = this.strokes.pop();
        if (lastStroke) {
            this.backupStrokes.push(lastStroke);
        }
        return lastStroke;
    }
    redo() {
        const lastBackupStroke = this.backupStrokes.pop();
        if (lastBackupStroke) {
            this.strokes.push(lastBackupStroke);
        }
        return lastBackupStroke;
    }
    getStrokes() {
        return this.strokes;
    }
}
class Room {
    constructor(name) {
        this.name = name;
        this.participants = new Set();
    }
    addParticipant(username) {
        this.participants.add(username);
    }
    removeParticipant(username) {
        this.participants.delete(username);
    }
    getParticipants() {
        return Array.from(this.participants);
    }
}
// In-memory storage
const rooms = {};
const roomDrawings = {};
const socketUserMap = {};
// Helper functions
const emitRoomList = () => io.emit("roomList", Object.keys(rooms));
const emitParticipantsUpdate = (roomName) => io.to(roomName).emit("updateParticipants", rooms[roomName].getParticipants());
// Criar uma nova sala
const handleCreateRoom = (roomName) => {
    if (!rooms[roomName]) {
        rooms[roomName] = new Room(roomName);
        roomDrawings[roomName] = new RoomDrawing();
        console.log(`Room created: ${roomName}`);
        emitRoomList();
    }
};
// Adicionar participante
const handleJoinRoom = (socket, { username, room }) => {
    if (!rooms[room]) {
        console.log(`Room ${room} does not exist`);
        return;
    }
    const currentRoom = rooms[room];
    currentRoom.addParticipant(username);
    socket.join(room);
    socketUserMap[socket.id] = { username, room };
    io.to(room).emit("newMessageChat", { username, message: `joined the room.` });
    const roomDrawing = roomDrawings[room];
    if (roomDrawing) {
        socket.emit("draw", { strokes: roomDrawing.getStrokes() });
    }
    emitParticipantsUpdate(room);
    console.log(`${username} joined room ${room}`);
};
const handleLeaveRoom = (socket, { username, room }) => {
    var _a;
    console.log(`${username} left room ${room}`);
    io.to(room).emit("newMessageChat", { username, message: `left the room.` });
    rooms[room].removeParticipant(username);
    emitParticipantsUpdate(room);
    if (((_a = socketUserMap[socket.id]) === null || _a === void 0 ? void 0 : _a.room) === room)
        delete socketUserMap[socket.id];
    socket.leave(room);
    // Remover sala se estiver vazia
    const participants = rooms[room].getParticipants();
    if (participants.length === 0) {
        delete rooms[room];
        delete roomDrawings[room];
        console.log(`Room ${room} is now empty and has been removed.`);
        emitRoomList();
    }
};
const handleDisconnect = (socket) => {
    const userInfo = socketUserMap[socket.id];
    if (!userInfo) {
        console.log(`No user info found for socket ${socket.id}`);
        return;
    }
    const { username, room } = userInfo;
    console.log(`User ${username} disconnected from room ${room}`);
    io.to(room).emit("newMessageChat", { username, message: `disconnected.` });
    delete socketUserMap[socket.id];
    rooms[room].removeParticipant(username);
    emitParticipantsUpdate(room);
    const participants = rooms[room].getParticipants();
    io.to(room).emit("updateParticipants", participants);
    if (participants.length === 0) {
        delete rooms[room];
        delete roomDrawings[room];
        console.log(`Room ${room} is now empty and has been removed.`);
        emitRoomList();
    }
};
const handleDrawingActions = (socket) => {
    socket.on("draw", ({ room, strokes }) => {
        const roomDrawing = roomDrawings[room];
        if (!roomDrawing)
            return;
        roomDrawing.addStrokes(strokes);
        io.to(room).emit("draw", { strokes });
    });
    socket.on("clearDraw", ({ room }) => {
        const roomDrawing = roomDrawings[room];
        if (!roomDrawing)
            return;
        roomDrawing.clear();
        io.to(room).emit("clearDraw");
    });
    socket.on("undoDraw", ({ room }) => {
        const roomDrawing = roomDrawings[room];
        if (!roomDrawing)
            return;
        roomDrawing.undo();
        io.to(room).emit("undoDraw");
    });
    socket.on("redoDraw", ({ room }) => {
        const roomDrawing = roomDrawings[room];
        if (!roomDrawing)
            return;
        roomDrawing.redo();
        io.to(room).emit("redoDraw");
    });
};
// Socket.IO setup
io.on("connection", (socket) => {
    console.log(`Client connected: ${socket.id}`);
    socket.emit("roomList", Object.keys(rooms));
    socket.on("createRoom", (roomName) => handleCreateRoom(roomName));
    socket.on("joinRoom", (data) => handleJoinRoom(socket, data));
    socket.on("leaveRoom", (data) => handleLeaveRoom(socket, data));
    socket.on("sendMessageChat", ({ username, room, message }) => io.to(room).emit("newMessageChat", { username, message }));
    socket.on("sendAnswerChat", ({ username, room, answer }) => io.to(room).emit("newAnswerChat", { username, answer }));
    handleDrawingActions(socket);
    socket.on("disconnect", () => handleDisconnect(socket));
});
// Start server
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
