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
const roomManager_1 = require("./rooms/roomManager");
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
// In-memory storage
const roomDrawings = {};
const backupRoomDrawings = {};
const availableRooms = new Set();
const socketUserMap = {};
// Helper functions
const emitRoomList = () => io.emit("roomList", Array.from(availableRooms));
const emitParticipantsUpdate = (room) => io.to(room).emit("updateParticipants", (0, roomManager_1.getRoomParticipants)(room));
// Event Handlers
const handleCreateRoom = (roomName) => {
    if (!availableRooms.has(roomName)) {
        availableRooms.add(roomName);
        console.log(`Room created: ${roomName}`);
        emitRoomList();
    }
};
const handleJoinRoom = (socket, { username, room }) => {
    if (!availableRooms.has(room)) {
        console.log(`Room ${room} does not exist`);
        return;
    }
    socket.join(room);
    (0, roomManager_1.createRoom)(room, username);
    socketUserMap[socket.id] = { username, room };
    io.to(room).emit("newMessageChat", { username, message: `joined the room.` });
    if (roomDrawings[room]) {
        socket.emit("draw", { strokes: roomDrawings[room] });
    }
    emitParticipantsUpdate(room);
    console.log(`${username} joined room ${room}`);
};
const handleLeaveRoom = (socket, { username, room }) => {
    var _a;
    console.log(`${username} left room ${room}`);
    io.to(room).emit("newMessageChat", { username, message: `left the room.` });
    (0, roomManager_1.removeParticipant)(room, username, availableRooms);
    emitParticipantsUpdate(room);
    if (((_a = socketUserMap[socket.id]) === null || _a === void 0 ? void 0 : _a.room) === room)
        delete socketUserMap[socket.id];
    socket.leave(room);
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
    (0, roomManager_1.removeParticipant)(room, username, availableRooms);
    emitParticipantsUpdate(room);
    const participants = (0, roomManager_1.getRoomParticipants)(room);
    io.to(room).emit("updateParticipants", participants);
    if (participants.length === 0) {
        availableRooms.delete(room);
        console.log(`Room ${room} is now empty and has been removed.`);
        emitRoomList();
    }
};
const handleDrawingActions = (socket) => {
    socket.on("draw", ({ room, strokes }) => {
        roomDrawings[room] = roomDrawings[room] || [];
        backupRoomDrawings[room] = backupRoomDrawings[room] || [];
        roomDrawings[room].push(...strokes);
        io.to(room).emit("draw", { strokes });
    });
    socket.on("clearDraw", ({ room }) => {
        roomDrawings[room] = [];
        backupRoomDrawings[room] = [];
        io.to(room).emit("clearDraw");
    });
    socket.on("undoDraw", ({ room }) => {
        var _a;
        const poppedValue = (_a = roomDrawings[room]) === null || _a === void 0 ? void 0 : _a.pop();
        if (poppedValue)
            backupRoomDrawings[room].push(poppedValue);
        io.to(room).emit("undoDraw");
    });
    socket.on("redoDraw", ({ room }) => {
        var _a;
        const poppedValue = (_a = backupRoomDrawings[room]) === null || _a === void 0 ? void 0 : _a.pop();
        if (poppedValue)
            roomDrawings[room].push(poppedValue);
        io.to(room).emit("redoDraw");
    });
};
// Socket.IO setup
io.on("connection", (socket) => {
    console.log(`Client connected: ${socket.id}`);
    socket.emit("roomList", Array.from(availableRooms));
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
