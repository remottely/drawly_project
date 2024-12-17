"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Message = exports.Answer = exports.RoomUserAnswerSocket = exports.RoomUserMessageSocket = exports.RoomUserSocket = exports.RoomDrawingSocket = exports.RoomSocket = exports.Room = exports.Drawing = exports.Stroke = exports.Offset = void 0;
exports.handleUserDisconnect = handleUserDisconnect;
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
// Classes
class Offset {
    constructor(dx, dy) {
        this.dx = dx;
        this.dy = dy;
    }
}
exports.Offset = Offset;
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
exports.Stroke = Stroke;
class Drawing {
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
exports.Drawing = Drawing;
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
exports.Room = Room;
// Memory storage
class RoomSocket {
    constructor(roomName) {
        this.roomName = roomName;
    }
}
exports.RoomSocket = RoomSocket;
class RoomDrawingSocket extends RoomSocket {
    constructor(roomName, strokes) {
        super(roomName);
        this.strokes = strokes;
    }
}
exports.RoomDrawingSocket = RoomDrawingSocket;
class RoomUserSocket extends RoomSocket {
    constructor(roomName, username) {
        super(roomName);
        this.username = username;
    }
}
exports.RoomUserSocket = RoomUserSocket;
class RoomUserMessageSocket extends RoomUserSocket {
    constructor(roomName, username, message) {
        super(roomName, username);
        this.message = message;
    }
}
exports.RoomUserMessageSocket = RoomUserMessageSocket;
class RoomUserAnswerSocket extends RoomUserSocket {
    constructor(roomName, username, answer) {
        super(roomName, username);
        this.answer = answer;
    }
}
exports.RoomUserAnswerSocket = RoomUserAnswerSocket;
class Answer {
    constructor(username, answer, isCorrect) {
        this.username = username;
        this.answer = answer;
        this.isCorrect = isCorrect;
    }
}
exports.Answer = Answer;
class Message {
    constructor(username, message, icon) {
        this.username = username;
        this.message = message;
        this.icon = icon;
    }
}
exports.Message = Message;
const rooms = {};
const roomDrawings = {};
const roomUsers = {};
const minimumNumberOfPlayers = 2;
const wordsList = [
    "cat", "dog", "house", "car", "tree", "flower", "sun", "moon", "book", "plane",
    "river", "mountain", "beach", "fish", "bird", "computer", "phone", "chair", "table",
];
class RoomManager {
    static emitRoomList() {
        return io.emit('roomList', Object.keys(rooms));
    }
    static emitParticipantsUpdate(roomName) {
        var _a;
        return io.to(roomName).emit('updateParticipants', ((_a = rooms[roomName]) === null || _a === void 0 ? void 0 : _a.getParticipants()) || []);
    }
    static create({ roomName }) {
        if (!rooms[roomName]) {
            rooms[roomName] = new Room(roomName);
            roomDrawings[roomName] = new Drawing();
            console.log(`Room created: ${roomName}`);
            RoomManager.emitRoomList();
        }
    }
    static join(socket, { roomName, username }) {
        var _a;
        if (!rooms[roomName]) {
            console.log(`Room ${roomName} does not exist`);
            return;
        }
        const currentRoom = rooms[roomName];
        currentRoom.addParticipant(username);
        socket.join(roomName);
        roomUsers[socket.id] = { roomName, username };
        io.to(roomName).emit('message:new', { icon: 'info', username, message: "joined" });
        socket.emit('drawing:draw', { strokes: (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.getStrokes() });
        RoomManager.emitParticipantsUpdate(roomName);
        console.log(`${username} joined room ${roomName}`);
    }
    static leave(socket, { username, roomName }) {
        var _a, _b, _c;
        console.log(`${username} left room ${roomName}`);
        io.to(roomName).emit('message:new', { icon: 'user', username, message: "left" });
        (_a = rooms[roomName]) === null || _a === void 0 ? void 0 : _a.removeParticipant(username);
        socket.leave(roomName);
        if (((_b = roomUsers[socket.id]) === null || _b === void 0 ? void 0 : _b.roomName) === roomName)
            delete roomUsers[socket.id];
        RoomManager.emitParticipantsUpdate(roomName);
        if (((_c = rooms[roomName]) === null || _c === void 0 ? void 0 : _c.getParticipants().length) === 0) {
            delete rooms[roomName];
            delete roomDrawings[roomName];
            console.log(`Room ${roomName} is now empty and has been removed.`);
            RoomManager.emitRoomList();
        }
    }
}
;
class AnswerActions {
    static send(socket, { roomName, username, answer }) {
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
        io.to(roomName).emit('answer:new', new Answer(username, answer, isCorrect));
    }
}
;
class MessageActions {
    static send({ roomName, username, message }) {
        io.to(roomName).emit('message:new', new Message(username, message, null));
    }
}
;
class DrawingActions {
    static draw({ roomName, strokes }) {
        var _a;
        (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.addStrokes(strokes);
        io.to(roomName).emit('drawing:draw', { strokes });
    }
    static clear({ roomName }) {
        var _a;
        (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.clear();
        io.to(roomName).emit('drawing:clear');
    }
    static undo({ roomName }) {
        var _a;
        (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.undo();
        io.to(roomName).emit('drawing:undo');
    }
    static redo({ roomName }) {
        var _a;
        (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.redo();
        io.to(roomName).emit('drawing:redo');
    }
}
;
class TurnManager {
    static startTurnTimer(roomName, totalDuration = 60) {
        const room = rooms[roomName];
        DrawingActions.clear({ roomName });
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
            TurnManager.startTurnTimer(roomName, totalDuration);
        }, totalDuration * 1000);
    }
}
;
class GameManager {
    static startTurns(socket, { roomName }) {
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
        TurnManager.startTurnTimer(roomName, 60);
    }
}
;
function handleUserDisconnect(socket) {
    const userInfo = roomUsers[socket.id];
    if (!userInfo) {
        console.log(`No user info found for socket ${socket.id}`);
        return;
    }
    const { roomName, username } = userInfo;
    console.log(`User ${username} disconnected from room ${roomName}`);
    RoomManager.leave(socket, { roomName, username });
}
;
// Socket.IO Configuration
io.on('connection', (socket) => {
    console.log(`Client connected: ${socket.id}`);
    socket.emit('roomList', Object.keys(rooms));
    socket.on('room:create', (data) => RoomManager.create(data));
    socket.on('room:join', (data) => RoomManager.join(socket, data));
    socket.on('room:leave', (data) => RoomManager.leave(socket, data));
    socket.on('drawing:draw', (data) => DrawingActions.draw(data));
    socket.on('drawing:clear', (data) => DrawingActions.clear(data));
    socket.on('drawing:undo', (data) => DrawingActions.undo(data));
    socket.on('drawing:redo', (data) => DrawingActions.redo(data));
    socket.on('answer:send', (data) => AnswerActions.send(socket, data));
    socket.on('message:send', (data) => MessageActions.send(data));
    socket.on('game:startTurns', (data) => GameManager.startTurns(socket, data));
    socket.on('disconnect', () => handleUserDisconnect(socket));
});
// Server startup
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
