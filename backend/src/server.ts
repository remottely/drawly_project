import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import http from "http";
import { Server, Socket } from "socket.io";
import { createRoom, getRoomParticipants, removeParticipant } from "./rooms/roomManager";

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Permitir conexões de qualquer origem (ajuste para produção)
  },
});

const PORT = process.env.PORT || 5555;

app.use(cors());
app.use(express.json());

type Stroke = {
  points: Array<[number, number]>;
  color: number;
  size: number;
  opacity: number;
  strokeType: string;
  filled: boolean;
};

// Map para armazenar o histórico de desenhos para cada sala
const roomDrawings: Record<string, Stroke[]> = {};
const backupRoomDrawings: Record<string, Stroke[]> = {};

// Set para gerenciar a lista de salas disponíveis
const availableRooms = new Set<string>();

// Mapa para associar socket.id ao username e salas
const socketUserMap: Record<string, { username: string; room: string }> = {};

io.on("connection", (socket: Socket) => {
  console.log(`Client connected: ${socket.id}`);

  // Envia a lista de salas disponíveis para o cliente conectado
  socket.emit("roomList", Array.from(availableRooms));

  // Evento para criar uma nova sala
  socket.on("createRoom", (roomName: string) => {
    if (!availableRooms.has(roomName)) {
      availableRooms.add(roomName);
      console.log(`Room created: ${roomName}`);
      io.emit("roomList", Array.from(availableRooms)); // Atualiza a lista de salas para todos os clientes
    }
  });

  // Evento para um usuário entrar em uma sala
  socket.on("joinRoom", ({ username, room }: { username: string; room: string }) => {
    if (!availableRooms.has(room)) {
      console.log(`Room ${room} does not exist`);
      return;
    }

    socket.join(room);
    createRoom(room, username);
    socketUserMap[socket.id] = { username, room };

    // Envia o desenho acumulado para o cliente que acabou de entrar
    if (roomDrawings[room]) {
      console.log(`Sending full drawing to client ${socket.id} for room ${room}`);
      socket.emit("draw", { strokes: roomDrawings[room] });
    } else {
      console.log(`No drawing available for room ${room}`);
    }

    const participants = getRoomParticipants(room);
    io.to(room).emit("updateParticipants", participants);

    console.log(`${username} joined room ${room}`);
    io.to(room).emit("newMessageChat", {
      username: username,
      message: `joined the room.`,
    });
  });

  // Evento para um usuário sair de uma sala
  socket.on("leaveRoom", ({ username, room }: { username: string; room: string }) => {
    console.log(`${username} left room ${room}`);

    io.to(room).emit("newMessageChat", {
      username: username,
      message: `left the room.`,
    });

    // Remove o participante da sala
    removeParticipant(availableRooms, room, username);

    const participants = getRoomParticipants(room);
    io.to(room).emit("updateParticipants", participants);

    // Remove a entrada do mapa se for o mesmo socket
    if (socketUserMap[socket.id]?.room === room) {
      delete socketUserMap[socket.id];
    }
    socket.leave(room);
  });

  // Event to handle sending messages
  socket.on("sendMessageChat", ({ username, room, message }: { username: string; room: string; message: string }) => {
    io.to(room).emit("newMessageChat", { username, message });
  });

  socket.on("sendAnswerChat", ({ username, room, answer }: { username: string; room: string; answer: string }) => {
    io.to(room).emit("newAnswerChat", { username, answer });
  });

  // Evento para lidar com os dados de desenho
  socket.on("draw", ({ room, strokes }: { room: string; strokes: Stroke[] }) => {
    console.log(`Drawing received for room ${room}:`, strokes);

    // Inicialize o histórico se ainda não existir
    if (!roomDrawings[room]) roomDrawings[room] = [];
    if (!backupRoomDrawings[room]) backupRoomDrawings[room] = [];

    // Adicione os novos strokes ao histórico
    roomDrawings[room].push(...strokes);

    // Envie os novos strokes para todos os clientes na sala
    io.to(room).emit("draw", { strokes });

    console.log(`Drawing broadcasted to room ${room}:`, strokes);
  });

  // Evento para limpar o desenho
  socket.on("clearDraw", ({ room }: { room: string }) => {
    console.log(`Clear draw received for room ${room}`);
    roomDrawings[room] = [];
    backupRoomDrawings[room] = [];
    io.to(room).emit("clearDraw");
  });

  // Evento para desfazer o último desenho
  socket.on("undoDraw", ({ room }: { room: string }) => {
    console.log(`Undo draw received for room ${room}`);
    const poppedValue = roomDrawings[room]?.pop();
    if (poppedValue) backupRoomDrawings[room].push(poppedValue);
    io.to(room).emit("undoDraw");
  });

  // Evento para refazer o último desenho
  socket.on("redoDraw", ({ room }: { room: string }) => {
    console.log(`Redo draw received for room ${room}`);
    const poppedValue = backupRoomDrawings[room]?.pop();
    if (poppedValue) roomDrawings[room].push(poppedValue);
    io.to(room).emit("redoDraw");
  });

  // Evento para lidar com desconexões
  socket.on("disconnect", () => {
    console.log(`Client disconnected: ${socket.id}`);

    // Recupera as informações do usuário antes de removê-lo
    const userInfo = socketUserMap[socket.id];

    if (userInfo) {
      const { username, room } = userInfo;

      console.log(`User ${username} disconnected from room ${room}`);
      console.log(`Attempting to remove participant ${username} from room ${room}`);

      // Notifica os participantes da sala sobre a desconexão
      io.sockets.in(room).emit("newMessageChat", {
        username: username,
        message: `disconnected.`,
      });

      // Remove o usuário do mapa
      delete socketUserMap[socket.id];

      // Remove o participante da sala
      removeParticipant(availableRooms, room, username);

      // Verifica e atualiza os participantes da sala
      const participants = getRoomParticipants(room);
      console.log(`Updated participants in room ${room}:`, participants);
      io.sockets.in(room).emit("updateParticipants", participants);

      // Se a sala estiver vazia, remove-a
      if (participants.length === 0) {
        availableRooms.delete(room);
        console.log(`Room ${room} is now empty and has been removed.`);
        io.emit("roomList", Array.from(availableRooms));
      }
    } else {
      console.log(`No user info found for socket ${socket.id}`);
    }
  });
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
