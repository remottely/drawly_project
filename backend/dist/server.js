"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GameManager = exports.TurnManager = exports.DrawingActions = exports.MessageChatActions = exports.AnswerChatActions = exports.RoomManager = exports.RoomUserAnswerDTO = exports.RoomUserMessageDTO = exports.RoomUserDTO = exports.RoomDrawingStrokeLastPointsDTO = exports.RoomDrawingStartStrokeDTO = exports.RoomDTO = exports.ErrorDTO = exports.Participant = exports.Turn = exports.Answer = exports.Message = exports.Room = exports.Drawing = exports.Stroke = exports.Offset = void 0;
exports.handleUserDisconnect = handleUserDisconnect;
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
var ErrorActionType;
(function (ErrorActionType) {
    ErrorActionType["nothing"] = "nothing";
    ErrorActionType["retry"] = "retry";
    ErrorActionType["ignore"] = "ignore";
    ErrorActionType["log"] = "log";
    ErrorActionType["pop"] = "pop";
    ErrorActionType["dialog"] = "dialog";
})(ErrorActionType || (ErrorActionType = {}));
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
    addStroke(newStroke) {
        this.strokes.push(newStroke);
    }
    addStrokeLastPoints(points) {
        if (this.strokes.length > 0) {
            const lastStroke = this.strokes[this.strokes.length - 1];
            lastStroke.points.push(...points);
        }
        else {
            console.error('No strokes available to add points to.');
        }
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
        this.currentDrawerTurnIndex = 0;
        this.currentWord = null;
        this.turnCount = 0;
    }
    addParticipant(participant) {
        this.participants.add(participant);
        this.turnQueue.push(participant);
    }
    removeParticipant(userId) {
        const participantToRemove = Array.from(this.participants).find((participant) => participant.userId === userId);
        if (participantToRemove) {
            this.participants.delete(participantToRemove);
            this.turnQueue = this.turnQueue.filter((participant) => participant.userId !== userId);
        }
        if (this.currentDrawerTurnIndex >= this.turnQueue.length) {
            this.currentDrawerTurnIndex = 0;
        }
    }
    getParticipants() {
        return Array.from(this.participants);
    }
    getCurrentDrawer() {
        return this.turnQueue[this.currentDrawerTurnIndex] || null;
    }
    advanceTurn() {
        this.turnCount++;
        this.currentDrawerTurnIndex = (this.turnCount) % this.turnQueue.length;
    }
}
exports.Room = Room;
class Message {
    constructor(icon, userId, username, text) {
        this.icon = icon;
        this.userId = userId;
        this.username = username;
        this.text = text;
    }
}
exports.Message = Message;
class Answer extends Message {
    constructor(icon, userId, username, text, isCorrect) {
        super(icon, userId, username, text);
        this.isCorrect = isCorrect;
    }
}
exports.Answer = Answer;
class Turn {
    constructor(word, turn, totalDuration, currentDrawerUserId, currentDrawerUsername) {
        this.word = word;
        this.turn = turn;
        this.totalDuration = totalDuration;
        this.currentDrawerUserId = currentDrawerUserId;
        this.currentDrawerUsername = currentDrawerUsername;
    }
}
exports.Turn = Turn;
class Participant {
    constructor(userId, username, userAvatar, isLogged) {
        this.userId = userId;
        this.username = username;
        this.userAvatar = userAvatar;
        this.isLogged = isLogged;
    }
}
exports.Participant = Participant;
// DTOs
class ErrorDTO {
    constructor(message, action) {
        this.message = message;
        this.action = action;
    }
}
exports.ErrorDTO = ErrorDTO;
class RoomDTO {
    constructor(roomName) {
        this.roomName = roomName;
    }
}
exports.RoomDTO = RoomDTO;
class RoomDrawingStartStrokeDTO extends RoomDTO {
    constructor(roomName, stroke) {
        super(roomName);
        this.stroke = stroke;
    }
}
exports.RoomDrawingStartStrokeDTO = RoomDrawingStartStrokeDTO;
class RoomDrawingStrokeLastPointsDTO extends RoomDTO {
    constructor(roomName, strokeLastPoints) {
        super(roomName);
        this.strokeLastPoints = strokeLastPoints;
    }
}
exports.RoomDrawingStrokeLastPointsDTO = RoomDrawingStrokeLastPointsDTO;
class RoomUserDTO extends RoomDTO {
    constructor(roomName, userId, username, userAvatar, isLogged) {
        super(roomName);
        this.userId = userId;
        this.username = username;
        this.userAvatar = userAvatar;
        this.isLogged = isLogged;
    }
}
exports.RoomUserDTO = RoomUserDTO;
class RoomUserMessageDTO extends RoomDTO {
    constructor(roomName, userId, username, text) {
        super(roomName);
        this.userId = userId;
        this.username = username;
        this.text = text;
    }
}
exports.RoomUserMessageDTO = RoomUserMessageDTO;
class RoomUserAnswerDTO extends RoomDTO {
    constructor(roomName, userId, username, text) {
        super(roomName);
        this.userId = userId;
        this.username = username;
        this.text = text;
    }
}
exports.RoomUserAnswerDTO = RoomUserAnswerDTO;
// Global variables
const rooms = {};
const roomDrawings = {};
const roomUsers = {};
const minNumberOfPlayers = 2;
// TODO(Kevin): Change back to 12
const maxmNumberOfPlayers = 3;
const wordsList = [
    "gato", "cachorro", "casa", "carro", "árvore", "flor", "sol", "lua", "livro", "avião",
    "rio", "montanha", "praia", "peixe", "pássaro", "computador", "telefone", "cadeira", "mesa",
    "namorados", "corda", "pular", "futebol", "bola", "cama", "travesseiro", "cobertor", "chave", "porta",
];
class RoomManager {
    static emitRoomList() {
        return io.emit('room:all', {
            allRooms: Object.keys(rooms)
        });
    }
    static emitParticipantsUpdate(roomName) {
        var _a;
        return io.to(roomName).emit('room:participants:update', {
            participants: ((_a = rooms[roomName]) === null || _a === void 0 ? void 0 : _a.getParticipants()) || []
        });
    }
    static create({ roomName }) {
        if (!rooms[roomName]) {
            rooms[roomName] = new Room(roomName);
            roomDrawings[roomName] = new Drawing();
            console.log(`Room created: ${roomName}`);
            RoomManager.emitRoomList();
        }
    }
    static join(socket, { roomName, userId, username, userAvatar, isLogged }, callback) {
        var _a;
        if (!rooms[roomName]) {
            console.log(`Room ${roomName} does not exist`);
            return;
        }
        const currentRoom = rooms[roomName];
        if (currentRoom.getParticipants().length >= maxmNumberOfPlayers) {
            var message = `Room ${roomName} is full. Maximum ${maxmNumberOfPlayers} players allowed.`;
            console.error(message);
            socket.emit('error', new ErrorDTO(message, ErrorActionType.pop));
            callback({ success: false });
            return;
        }
        currentRoom.addParticipant(new Participant(userId, username, userAvatar, isLogged));
        socket.join(roomName);
        roomUsers[socket.id] = { roomName, userId, username, userAvatar, isLogged };
        io.to(roomName).emit('chat:message', new Message('info', userId, username, "entrou"));
        socket.emit('drawing:stroke:all', { strokes: (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.getStrokes() });
        RoomManager.emitParticipantsUpdate(roomName);
        console.log(`${userId} - ${username} joined room ${roomName}`);
        callback({ success: true, turn: currentRoom.turnCount });
    }
    static leave(socket, { roomName, userId, username }) {
        var _a, _b, _c;
        console.log(`${userId} - ${username} left room ${roomName}`);
        io.to(roomName).emit('chat:message', new Message('info', userId, username, "saiu"));
        (_a = rooms[roomName]) === null || _a === void 0 ? void 0 : _a.removeParticipant(userId);
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
exports.RoomManager = RoomManager;
class AnswerChatActions {
    static guess(socket, { roomName, userId, username, text }) {
        const room = rooms[roomName];
        if (!room) {
            const message = `Room ${roomName} does not exist.`;
            console.error(message);
            socket.emit('error', new ErrorDTO(message, ErrorActionType.nothing));
            return;
        }
        const correctWord = room.currentWord;
        if (!correctWord) {
            const message = `No word is currently being drawn.`;
            console.error(`${message} in room ${roomName}.`);
            socket.emit('error', new ErrorDTO(message, ErrorActionType.nothing));
            return;
        }
        const isCorrect = correctWord.toLowerCase() === text.toLowerCase();
        const icon = isCorrect ? 'check' : null;
        io.to(roomName).emit('chat:answer:result', new Answer(icon, userId, username, text, isCorrect));
    }
}
exports.AnswerChatActions = AnswerChatActions;
class MessageChatActions {
    static send({ roomName, userId, username, text }) {
        io.to(roomName).emit('chat:message', new Message(null, userId, username, text));
    }
}
exports.MessageChatActions = MessageChatActions;
class DrawingActions {
    static strokeStart({ roomName, stroke }) {
        var _a;
        (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.addStroke(stroke);
        io.to(roomName).emit('drawing:stroke:start', { stroke });
    }
    static strokeLastPoints({ roomName, strokeLastPoints }) {
        var _a;
        (_a = roomDrawings[roomName]) === null || _a === void 0 ? void 0 : _a.addStrokeLastPoints(strokeLastPoints);
        io.to(roomName).emit('drawing:stroke:lastPoints', { strokeLastPoints });
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
exports.DrawingActions = DrawingActions;
;
class TurnManager {
    static startTurnTimer(roomName, totalDuration = 60) {
        const room = rooms[roomName];
        room.advanceTurn();
        DrawingActions.clear({ roomName });
        if (!room) {
            console.error(`Room ${roomName} not found.`);
            return;
        }
        if (room.getParticipants().length === 0) {
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
        io.to(roomName).emit('game:turn:new', new Turn(wordToDraw, room.turnCount, totalDuration * 1000, currentDrawer.userId, currentDrawer.username));
        console.log(`New turn started in room ${roomName}. Drawer: ${currentDrawer.username}, Word: ${wordToDraw}`);
        setTimeout(() => {
            // room.advanceTurn();
            TurnManager.startTurnTimer(roomName, totalDuration);
        }, totalDuration * 1000);
    }
}
exports.TurnManager = TurnManager;
class GameManager {
    static startTurns(socket, { roomName }) {
        const room = rooms[roomName];
        if (!room) {
            const message = `Room ${roomName} does not exist.`;
            console.error(message);
            socket.emit('error', new ErrorDTO(message, ErrorActionType.nothing));
            return;
        }
        if (room.getParticipants().length < minNumberOfPlayers) {
            const message = `Not enough players in the room ${roomName}. Minimum required: ${minNumberOfPlayers}.`;
            console.error(message);
            socket.emit('error', new ErrorDTO(message, ErrorActionType.nothing));
            return;
        }
        console.log(`Turns manually started for room ${roomName}`);
        // TODO(Kevin): PUT BACK: TurnManager.startTurnTimer(roomName, 60);
        TurnManager.startTurnTimer(roomName, 20);
    }
}
exports.GameManager = GameManager;
;
function handleUserDisconnect(socket) {
    const userInfo = roomUsers[socket.id];
    if (!userInfo) {
        // TODO(Kevin): do something here?
        console.log(`No user info found for socket ${socket.id}`);
        return;
    }
    const { roomName, userId, username } = userInfo;
    console.log(`User ${userId} - ${username} disconnected from room ${roomName}`);
    RoomManager.leave(socket, { roomName, userId, username, userAvatar: null, isLogged: false });
}
// Socket.IO Configuration
io.on('connection', (socket) => {
    console.log(`Client connected: ${socket.id}`);
    socket.emit('room:all', {
        allRooms: Object.keys(rooms)
    });
    socket.on('room:create', (data) => RoomManager.create(data));
    socket.on('room:join', (data, callback) => RoomManager.join(socket, data, callback));
    socket.on('room:leave', (data) => RoomManager.leave(socket, data));
    socket.on('drawing:stroke:start', (data) => DrawingActions.strokeStart(data));
    socket.on('drawing:stroke:lastPoints', (data) => DrawingActions.strokeLastPoints(data));
    socket.on('drawing:clear', (data) => DrawingActions.clear(data));
    socket.on('drawing:undo', (data) => DrawingActions.undo(data));
    socket.on('drawing:redo', (data) => DrawingActions.redo(data));
    socket.on('chat:answer:guess', (data) => AnswerChatActions.guess(socket, data));
    socket.on('chat:message', (data) => MessageChatActions.send(data));
    socket.on('game:turns:start', (data) => GameManager.startTurns(socket, data));
    socket.on('disconnect', () => handleUserDisconnect(socket));
});
// Server startup
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
