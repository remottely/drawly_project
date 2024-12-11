"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRoomParticipants = exports.removeParticipant = exports.createRoom = void 0;
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const express_1 = __importDefault(require("express"));
const http_1 = __importDefault(require("http"));
const socket_io_1 = require("socket.io");
dotenv_1.default.config();
const app = (0, express_1.default)();
const server = http_1.default.createServer(app);
const io = new socket_io_1.Server(server, {
    cors: {
        origin: "*", // Permitir conexões de qualquer origem (ajuste para produção)
    },
});
const PORT = process.env.PORT || 5555;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Map para armazenar o histórico de desenhos para cada sala
const roomDrawings = {};
const backupRoomDrawings = {};
// Set para gerenciar a lista de salas disponíveis
const availableRooms = new Set();
// Mapa para associar socket.id ao username e salas
const socketUserMap = {};
io.on("connection", (socket) => {
    console.log(`Client connected: ${socket.id}`);
    // // Verifica se o socket reconectou e restaura a sala
    // const previousUser = socketUserMap[socket.id];
    // if (previousUser) {
    //   const { username, room } = previousUser;
    //   console.log(`${username} reconnected to room ${room}`);
    //   socket.join(room);
    //   // Restaura desenhos e participantes
    //   if (roomDrawings[room]) {
    //     socket.emit("draw", { strokes: roomDrawings[room] });
    //   }
    //   const participants = getRoomParticipants(room);
    //   io.to(room).emit("updateParticipants", participants);
    // }
    // // Envia a lista de salas disponíveis para o cliente conectado
    // socket.emit("roomList", Array.from(availableRooms));
    // Evento para criar uma nova sala
    socket.on("createRoom", (roomName) => {
        if (!availableRooms.has(roomName)) {
            availableRooms.add(roomName);
            console.log(`Room created: ${roomName}`);
            io.emit("roomList", Array.from(availableRooms)); // Atualiza a lista de salas para todos os clientes
        }
    });
    // Evento para um usuário entrar em uma sala
    socket.on("joinRoom", ({ username, room }) => {
        if (!availableRooms.has(room)) {
            console.log(`Room ${room} does not exist`);
            return;
        }
        socket.join(room);
        (0, exports.createRoom)(room, username);
        socketUserMap[socket.id] = { username, room };
        // Envia o desenho acumulado para o cliente que acabou de entrar
        if (roomDrawings[room]) {
            console.log(`Sending full drawing to client ${socket.id} for room ${room}`);
            socket.emit("draw", { strokes: roomDrawings[room] });
        }
        else {
            console.log(`No drawing available for room ${room}`);
        }
        const participants = (0, exports.getRoomParticipants)(room);
        io.to(room).emit("updateParticipants", participants);
        console.log(`${username} joined room ${room}`);
        io.to(room).emit("newMessageChat", {
            username: "System",
            message: `${username} joined the room.`,
        });
    });
    // Evento para um usuário sair de uma sala
    socket.on("leaveRoom", ({ username, room }) => {
        var _a;
        console.log(`${username} left room ${room}`);
        // socket.leave(room);
        // Remove o participante da sala
        (0, exports.removeParticipant)(availableRooms, room, username);
        io.to(room).emit("newMessageChat", {
            username: "System",
            message: `${username} left the room.`,
        });
        const participants = (0, exports.getRoomParticipants)(room);
        io.to(room).emit("updateParticipants", participants);
        // Remove a entrada do mapa se for o mesmo socket
        if (((_a = socketUserMap[socket.id]) === null || _a === void 0 ? void 0 : _a.room) === room) {
            delete socketUserMap[socket.id];
        }
        socket.leave(room);
    });
    // Event to handle sending messages
    socket.on("sendMessageChat", ({ username, room, message }) => {
        io.to(room).emit("newMessageChat", { username, message });
    });
    socket.on("sendAnswerChat", ({ username, room, answer }) => {
        io.to(room).emit("newAnswerChat", { username, answer });
    });
    // Evento para lidar com os dados de desenho
    socket.on("draw", ({ room, strokes }) => {
        console.log(`Drawing received for room ${room}:`, strokes);
        // Inicialize o histórico se ainda não existir
        if (!roomDrawings[room])
            roomDrawings[room] = [];
        if (!backupRoomDrawings[room])
            backupRoomDrawings[room] = [];
        // Adicione os novos strokes ao histórico
        roomDrawings[room].push(...strokes);
        // Envie os novos strokes para todos os clientes na sala
        io.to(room).emit("draw", { strokes });
        console.log(`Drawing broadcasted to room ${room}:`, strokes);
    });
    // Evento para limpar o desenho
    socket.on("clearDraw", ({ room }) => {
        console.log(`Clear draw received for room ${room}`);
        roomDrawings[room] = [];
        backupRoomDrawings[room] = [];
        io.to(room).emit("clearDraw");
    });
    // Evento para desfazer o último desenho
    socket.on("undoDraw", ({ room }) => {
        var _a;
        console.log(`Undo draw received for room ${room}`);
        const poppedValue = (_a = roomDrawings[room]) === null || _a === void 0 ? void 0 : _a.pop();
        if (poppedValue)
            backupRoomDrawings[room].push(poppedValue);
        io.to(room).emit("undoDraw");
    });
    // Evento para refazer o último desenho
    socket.on("redoDraw", ({ room }) => {
        var _a;
        console.log(`Redo draw received for room ${room}`);
        const poppedValue = (_a = backupRoomDrawings[room]) === null || _a === void 0 ? void 0 : _a.pop();
        if (poppedValue)
            roomDrawings[room].push(poppedValue);
        io.to(room).emit("redoDraw");
    });
    // Evento para lidar com desconexões
    socket.on("disconnect", () => {
        console.log(`Client disconnected: ${socket.id}`);
        const userInfo = socketUserMap[socket.id];
        if (userInfo) {
            const { username, room } = userInfo;
            console.log(`Removing ${username} from room ${room}`);
            (0, exports.removeParticipant)(availableRooms, room, username);
            // Atualiza os participantes para todos os sockets restantes na sala
            const participants = (0, exports.getRoomParticipants)(room);
            io.to(room).emit("updateParticipants", participants);
            // Remove o socket do mapa
            delete socketUserMap[socket.id];
        }
    });
});
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
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
const removeParticipant = (availableRooms, room, username) => {
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
