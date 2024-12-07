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
const app = (0, express_1.default)();
const server = http_1.default.createServer(app);
const io = new socket_io_1.Server(server, {
    cors: {
        origin: "*", // Allow connections from any source (change for production)
    },
});
const PORT = process.env.PORT || 5555;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Map to store drawing history for each room
const roomDrawings = {};
const backupRoomDrawings = {};
// Set to manage the list of available rooms
const availableRooms = new Set();
io.on("connection", (socket) => {
    console.log(`Client connected: ${socket.id}`);
    // Send the list of available rooms to the newly connected client
    socket.emit("roomList", Array.from(availableRooms));
    // Event to create a new room
    socket.on("createRoom", (roomName) => {
        if (!availableRooms.has(roomName)) {
            availableRooms.add(roomName);
            console.log(`Room created: ${roomName}`);
            io.emit("roomList", Array.from(availableRooms)); // Broadcast updated room list to all clients
        }
    });
    // Event when a user joins a room
    socket.on("joinRoom", ({ username, room }) => {
        if (!availableRooms.has(room)) {
            console.log(`Room ${room} does not exist`);
            return;
        }
        socket.join(room);
        (0, roomManager_1.createRoom)(room, username);
        // Send the accumulated drawing to the client who just joined
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
        io.to(room).emit("newMessageChat", {
            username: "System",
            message: `${username} joined the room.`,
        });
    });
    // Event for leaving a room
    socket.on("leaveRoom", ({ username, room }) => {
        console.log(`${username} left room ${room}`);
        socket.leave(room);
        io.to(room).emit("newMessageChat", {
            username: "System",
            message: `${username} left the room.`,
        });
        const participants = (0, roomManager_1.getRoomParticipants)(room);
        io.to(room).emit("updateParticipants", participants);
    });
    // Event to handle sending messages
    socket.on("sendMessageChat", ({ username, room, message }) => {
        io.to(room).emit("newMessageChat", { username, message });
    });
    socket.on("sendAnswerChat", ({ username, room, answer }) => {
        io.to(room).emit("newAnswerChat", { username, answer });
    });
    // Event to handle drawing data
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
        console.log(`Clear draw broadcasted to room ${room}`);
    });
    socket.on("undoDraw", ({ room }) => {
        console.log(`Undo draw received for room ${room}`);
        const poppedValue = roomDrawings[room].pop();
        if (poppedValue)
            backupRoomDrawings[room].push(poppedValue);
        io.to(room).emit("undoDraw");
        console.log(`Undo draw broadcasted to room ${room}`);
    });
    socket.on("redoDraw", ({ room }) => {
        console.log(`Redo draw received for room ${room}`);
        const poppedValue = backupRoomDrawings[room].pop();
        if (poppedValue)
            roomDrawings[room].push(poppedValue);
        io.to(room).emit("redoDraw");
        console.log(`Redo draw broadcasted to room ${room}`);
    });
    // Event for handling disconnection
    socket.on("disconnect", () => {
        console.log(`Client disconnected: ${socket.id}`);
    });
});
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
