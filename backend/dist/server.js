"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
// Dependencies and initial configuration
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
        this.turnQueue = [];
        this.currentTurnIndex = 0;
        this.currentWord = null;
    }
    addParticipant(username) {
        this.participants.add(username);
        this.turnQueue.push(username);
    }
    removeParticipant(username) {
        this.participants.delete(username);
        this.turnQueue = this.turnQueue.filter((user) => user !== username);
        if (this.currentTurnIndex >= this.turnQueue.length) {
            this.currentTurnIndex = 0;
        }
    }
    getParticipants() {
        return Array.from(this.participants);
    }
    getCurrentDrawer() {
        return this.turnQueue[this.currentTurnIndex];
    }
    advanceTurn() {
        this.currentTurnIndex = (this.currentTurnIndex + 1) % this.turnQueue.length;
    }
}
const rooms = {};
const roomDrawings = {};
const socketUserMap = {};
const minimumNumberOfPlayers = 2;
const wordsList = [
    "cat", "dog", "house", "car", "tree", "flower", "sun", "moon", "book", "plane",
    "river", "mountain", "beach", "fish", "bird", "computer", "phone", "chair", "table",
];
// Auxiliary functions
const emitRoomList = () => io.emit('roomList', Object.keys(rooms));
const emitParticipantsUpdate = (roomName) => { var _a; return io.to(roomName).emit('updateParticipants', ((_a = rooms[roomName]) === null || _a === void 0 ? void 0 : _a.getParticipants()) || []); };
const handleRoomManagement = {
    create({ roomName }) {
        if (!rooms[roomName]) {
            rooms[roomName] = new Room(roomName);
            roomDrawings[roomName] = new RoomDrawing();
            console.log(`Room created: ${roomName}`);
            emitRoomList();
        }
    },
    join(socket, { username, roomName }) {
        var _a;
        if (!rooms[roomName]) {
            console.log(`Room ${roomName} does not exist`);
            return;
        }
        const currentRoom = rooms[roomName];
        currentRoom.addParticipant(username);
        socket.join(roomName);
        socketUserMap[socket.id] = { username, roomName };
        io.to(roomName).emit('message:new', { username, message: "joined the room." });
        socket.emit('drawing:draw', { strokes: (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.getStrokes() });
        emitParticipantsUpdate(roomName);
        console.log(`${username} joined room ${roomName}`);
    },
    leave(socket, { username, roomName }) {
        var _a, _b, _c;
        console.log(`${username} left room ${roomName}`);
        io.to(roomName).emit('message:new', { username, message: "left the room." });
        (_a = rooms[roomName]) === null || _a === void 0 ? void 0 : _a.removeParticipant(username);
        socket.leave(roomName);
        if (((_b = socketUserMap[socket.id]) === null || _b === void 0 ? void 0 : _b.roomName) === roomName)
            delete socketUserMap[socket.id];
        emitParticipantsUpdate(roomName);
        if (((_c = rooms[roomName]) === null || _c === void 0 ? void 0 : _c.getParticipants().length) === 0) {
            delete rooms[roomName];
            delete roomDrawings[roomName];
            console.log(`Room ${roomName} is now empty and has been removed.`);
            emitRoomList();
        }
    },
};
const handleAnswerActions = {
    sendAnswer(socket, { username, roomName, answer }) {
        const room = rooms[roomName];
        if (!room) {
            console.error(`Room ${roomName} not found.`);
            socket.emit('error', { message: `Room ${roomName} does not exist.` });
            return;
        }
        const correctWord = room.currentWord;
        if (!correctWord) {
            console.error(`No word is being drawn in room ${roomName}.`);
            socket.emit('error', { message: `No word is currently being drawn.` });
            return;
        }
        const isCorrect = correctWord.toLowerCase() === answer.toLowerCase();
        io.to(roomName).emit('answer:new', { username, answer, isCorrect });
    },
};
const handleMessageActions = {
    sendMessage({ username, roomName, message }) {
        io.to(roomName).emit('message:new', { username, message });
    },
};
const handleDrawingActions = {
    draw({ roomName, strokes }) {
        var _a;
        (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.addStrokes(strokes);
        io.to(roomName).emit('drawing:draw', { strokes });
    },
    clear({ roomName }) {
        var _a;
        (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.clear();
        io.to(roomName).emit('drawing:clear');
    },
    undo({ roomName }) {
        var _a;
        (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.undo();
        io.to(roomName).emit('drawing:undo');
    },
    redo({ roomName }) {
        var _a;
        (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.redo();
        io.to(roomName).emit('drawing:redo');
    },
};
const handleTurnActions = {
    startTurnTimer(roomName, totalDuration = 60) {
        const room = rooms[roomName];
        handleDrawingActions.clear({ roomName });
        if (!room) {
            console.error(`Room ${roomName} not found.`);
            return;
        }
        const participants = room.getParticipants();
        if (participants.length === 0) {
            console.error(`No participants available in room ${roomName}`);
            return;
        }
        const currentDrawer = room.getCurrentDrawer();
        if (!currentDrawer) {
            console.error(`Failed to get the current drawer in room ${roomName}`);
            return;
        }
        const wordToDraw = wordsList[Math.floor(Math.random() * wordsList.length)];
        room.currentWord = wordToDraw;
        io.to(roomName).emit('newTurn', {
            currentDrawer,
            word: wordToDraw,
            totalDuration: totalDuration * 1000,
        });
        console.log(`New turn started in room ${roomName}. Drawer: ${currentDrawer}, Word: ${wordToDraw}`);
        setTimeout(() => {
            room.advanceTurn();
            handleTurnActions.startTurnTimer(roomName, totalDuration);
        }, totalDuration * 1000);
    },
};
const handleGameActions = {
    startTurns(socket, { roomName }) {
        const room = rooms[roomName];
        if (!room) {
            console.error(`Room ${roomName} not found.`);
            socket.emit('error', { message: `Room ${roomName} does not exist.` });
            return;
        }
        if (room.getParticipants().length < minimumNumberOfPlayers) {
            console.error(`Not enough players in room ${roomName}. Minimum required: ${minimumNumberOfPlayers}`);
            socket.emit('error', { message: `Not enough players in the room. Minimum required: ${minimumNumberOfPlayers}.` });
            return;
        }
        console.log(`Turns manually started for room ${roomName}`);
        handleTurnActions.startTurnTimer(roomName, 60);
    },
};
const handleDisconnect = (socket) => {
    const userInfo = socketUserMap[socket.id];
    if (!userInfo) {
        console.log(`No user info found for socket ${socket.id}`);
        return;
    }
    const { username, roomName } = userInfo;
    console.log(`User ${username} disconnected from room ${roomName}`);
    handleRoomManagement.leave(socket, { username, roomName });
};
// Socket.IO Configuration
io.on('connection', (socket) => {
    console.log(`Client connected: ${socket.id}`);
    socket.emit('roomList', Object.keys(rooms));
    socket.on('room:create', (data) => handleRoomManagement.create(data));
    socket.on('room:join', (data) => handleRoomManagement.join(socket, data));
    socket.on('room:leave', (data) => handleRoomManagement.leave(socket, data));
    socket.on('drawing:draw', (data) => handleDrawingActions.draw(data));
    socket.on('drawing:clear', (data) => handleDrawingActions.clear(data));
    socket.on('drawing:undo', (data) => handleDrawingActions.undo(data));
    socket.on('drawing:redo', (data) => handleDrawingActions.redo(data));
    socket.on('answer:send', (data) => handleAnswerActions.sendAnswer(socket, data));
    socket.on('message:send', (data) => handleMessageActions.sendMessage(data));
    socket.on('game:startTurns', (data) => handleGameActions.startTurns(socket, data));
    socket.on('disconnect', () => handleDisconnect(socket));
});
// Server startup
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
