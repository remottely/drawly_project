"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
// Dependências e configuração inicial
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const express_1 = __importDefault(require("express"));
const http_1 = __importDefault(require("http"));
const socket_io_1 = require("socket.io");
dotenv_1.default.config();
const app = (0, express_1.default)();
const server = http_1.default.createServer(app);
const io = new socket_io_1.Server(server, { cors: { origin: "*" } });
const PORT = process.env.PORT || 5555;
// Middleware
app.use((0, cors_1.default)());
app.use(express_1.default.json());
var StrokeType;
(function (StrokeType) {
    StrokeType["normal"] = "normal";
    StrokeType["eraser"] = "eraser";
    StrokeType["line"] = "line";
    StrokeType["polygon"] = "polygon";
    StrokeType["square"] = "square";
    StrokeType["circle"] = "circle";
})(StrokeType || (StrokeType = {}));
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
        if (lastStroke)
            this.backupStrokes.push(lastStroke);
        return lastStroke;
    }
    redo() {
        const lastBackupStroke = this.backupStrokes.pop();
        if (lastBackupStroke)
            this.strokes.push(lastBackupStroke);
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
const rooms = {};
const roomDrawings = {};
const socketUserMap = {};
// Funções auxiliares
const emitRoomList = () => io.emit("roomList", Object.keys(rooms));
const emitParticipantsUpdate = (roomName) => { var _a; return io.to(roomName).emit("updateParticipants", ((_a = rooms[roomName]) === null || _a === void 0 ? void 0 : _a.getParticipants()) || []); };
const handleRoomManagement = {
    create(roomName) {
        if (!rooms[roomName]) {
            rooms[roomName] = new Room(roomName);
            roomDrawings[roomName] = new RoomDrawing();
            console.log(`Room created: ${roomName}`);
            emitRoomList();
        }
    },
    join(socket, { username, room }) {
        var _a;
        if (!rooms[room]) {
            console.log(`Room ${room} does not exist`);
            return;
        }
        const currentRoom = rooms[room];
        currentRoom.addParticipant(username);
        socket.join(room);
        socketUserMap[socket.id] = { username, room };
        io.to(room).emit("newMessageChat", { username, message: "joined the room." });
        socket.emit("draw", { strokes: (_a = roomDrawings[room]) === null || _a === void 0 ? void 0 : _a.getStrokes() });
        emitParticipantsUpdate(room);
        console.log(`${username} joined room ${room}`);
    },
    leave(socket, { username, room }) {
        var _a, _b, _c;
        console.log(`${username} left room ${room}`);
        io.to(room).emit("newMessageChat", { username, message: "left the room." });
        (_a = rooms[room]) === null || _a === void 0 ? void 0 : _a.removeParticipant(username);
        socket.leave(room);
        if (((_b = socketUserMap[socket.id]) === null || _b === void 0 ? void 0 : _b.room) === room)
            delete socketUserMap[socket.id];
        emitParticipantsUpdate(room);
        if (((_c = rooms[room]) === null || _c === void 0 ? void 0 : _c.getParticipants().length) === 0) {
            delete rooms[room];
            delete roomDrawings[room];
            console.log(`Room ${room} is now empty and has been removed.`);
            emitRoomList();
        }
    },
};
const handleDrawingActions = (socket) => {
    socket.on("draw", ({ room, strokes }) => {
        var _a;
        (_a = roomDrawings[room]) === null || _a === void 0 ? void 0 : _a.addStrokes(strokes);
        io.to(room).emit("draw", { strokes });
    });
    socket.on("clearDraw", ({ room }) => {
        var _a;
        (_a = roomDrawings[room]) === null || _a === void 0 ? void 0 : _a.clear();
        io.to(room).emit("clearDraw");
    });
    socket.on("undoDraw", ({ room }) => {
        var _a;
        (_a = roomDrawings[room]) === null || _a === void 0 ? void 0 : _a.undo();
        io.to(room).emit("undoDraw");
    });
    socket.on("redoDraw", ({ room }) => {
        var _a;
        (_a = roomDrawings[room]) === null || _a === void 0 ? void 0 : _a.redo();
        io.to(room).emit("redoDraw");
    });
};
const handleDisconnect = (socket) => {
    const userInfo = socketUserMap[socket.id];
    if (!userInfo) {
        console.log(`No user info found for socket ${socket.id}`);
        return;
    }
    const { username, room } = userInfo;
    console.log(`User ${username} disconnected from room ${room}`);
    handleRoomManagement.leave(socket, { username, room });
};
// Configuração do Socket.IO
io.on("connection", (socket) => {
    console.log(`Client connected: ${socket.id}`);
    socket.emit("roomList", Object.keys(rooms));
    socket.on("createRoom", (roomName) => handleRoomManagement.create(roomName));
    socket.on("joinRoom", (data) => handleRoomManagement.join(socket, data));
    socket.on("leaveRoom", (data) => handleRoomManagement.leave(socket, data));
    socket.on("sendMessageChat", ({ username, room, message }) => io.to(room).emit("newMessageChat", { username, message }));
    socket.on("sendAnswerChat", ({ username, room, answer }) => io.to(room).emit("newAnswerChat", { username, answer }));
    handleDrawingActions(socket);
    socket.on("disconnect", () => handleDisconnect(socket));
});
// Inicialização do servidor
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
