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
// Express and Socket.IO setup
const app = (0, express_1.default)();
const server = http_1.default.createServer(app);
const io = new socket_io_1.Server(server, {
    cors: {
        origin: "*", // Allow connections from any origin (adjust for production)
    },
});
const PORT = process.env.PORT || 5555;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// In-memory storage
const roomDrawings = {};
const backupRoomDrawings = {};
const availableRooms = new Set();
const socketUserMap = {};
// Socket.IO event handlers
io.on("connection", (socket) => {
    console.log(`Client connected: ${socket.id}`);
    // Emit available rooms to the newly connected client
    socket.emit("roomList", Array.from(availableRooms));
    socket.on("createRoom", (roomName) => {
        if (!availableRooms.has(roomName)) {
            availableRooms.add(roomName);
            console.log(`Room created: ${roomName}`);
            io.emit("roomList", Array.from(availableRooms));
        }
    });
    socket.on("joinRoom", ({ username, room }) => {
        if (!availableRooms.has(room)) {
            console.log(`Room ${room} does not exist`);
            return;
        }
        socket.join(room);
        (0, roomManager_1.createRoom)(room, username);
        socketUserMap[socket.id] = { username, room };
        // Send accumulated drawing to the new client
        if (roomDrawings[room]) {
            console.log(`Sending full drawing to client ${socket.id} for room ${room}`);
            socket.emit("draw", { strokes: roomDrawings[room] });
        }
        else {
            console.log(`No drawing available for room ${room}`);
        }
        const participants = (0, roomManager_1.getRoomParticipants)(room);
        io.to(room).emit("updateParticipants", participants);
        console.log(`${username} joined room ${room}`);
        io.to(room).emit("newMessageChat", { username, message: `joined the room.` });
    });
    socket.on("leaveRoom", ({ username, room }) => {
        var _a;
        console.log(`${username} left room ${room}`);
        io.to(room).emit("newMessageChat", { username, message: `left the room.` });
        (0, roomManager_1.removeParticipant)(room, username, availableRooms);
        const participants = (0, roomManager_1.getRoomParticipants)(room);
        io.to(room).emit("updateParticipants", participants);
        if (((_a = socketUserMap[socket.id]) === null || _a === void 0 ? void 0 : _a.room) === room) {
            delete socketUserMap[socket.id];
        }
        socket.leave(room);
    });
    socket.on("sendMessageChat", ({ username, room, message }) => {
        io.to(room).emit("newMessageChat", { username, message });
    });
    socket.on("sendAnswerChat", ({ username, room, answer }) => {
        io.to(room).emit("newAnswerChat", { username, answer });
    });
    socket.on("draw", ({ room, strokes }) => {
        console.log(`Drawing received for room ${room}:`, strokes);
        if (!roomDrawings[room])
            roomDrawings[room] = [];
        if (!backupRoomDrawings[room])
            backupRoomDrawings[room] = [];
        roomDrawings[room].push(...strokes);
        io.to(room).emit("draw", { strokes });
        console.log(`Drawing broadcasted to room ${room}:`, strokes);
    });
    socket.on("clearDraw", ({ room }) => {
        console.log(`Clear draw received for room ${room}`);
        roomDrawings[room] = [];
        backupRoomDrawings[room] = [];
        io.to(room).emit("clearDraw");
    });
    socket.on("undoDraw", ({ room }) => {
        var _a;
        console.log(`Undo draw received for room ${room}`);
        const poppedValue = (_a = roomDrawings[room]) === null || _a === void 0 ? void 0 : _a.pop();
        if (poppedValue)
            backupRoomDrawings[room].push(poppedValue);
        io.to(room).emit("undoDraw");
    });
    socket.on("redoDraw", ({ room }) => {
        var _a;
        console.log(`Redo draw received for room ${room}`);
        const poppedValue = (_a = backupRoomDrawings[room]) === null || _a === void 0 ? void 0 : _a.pop();
        if (poppedValue)
            roomDrawings[room].push(poppedValue);
        io.to(room).emit("redoDraw");
    });
    socket.on("disconnect", () => {
        console.log(`Client disconnected: ${socket.id}`);
        const userInfo = socketUserMap[socket.id];
        if (userInfo) {
            const { username, room } = userInfo;
            console.log(`User ${username} disconnected from room ${room}`);
            io.to(room).emit("newMessageChat", { username, message: `disconnected.` });
            delete socketUserMap[socket.id];
            (0, roomManager_1.removeParticipant)(room, username, availableRooms);
            const participants = (0, roomManager_1.getRoomParticipants)(room);
            io.to(room).emit("updateParticipants", participants);
            if (participants.length === 0) {
                availableRooms.delete(room);
                console.log(`Room ${room} is now empty and has been removed.`);
                io.emit("roomList", Array.from(availableRooms));
            }
        }
        else {
            console.log(`No user info found for socket ${socket.id}`);
        }
    });
});
// Start server
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
