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
};

// Map para armazenar o histórico de desenhos para cada sala
const roomDrawings: Record<string, Stroke[]> = {};
const backupRoomDrawings: Record<string, Stroke[]> = {};

// Set para gerenciar a lista de salas disponíveis
const availableRooms = new Set<string>();

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
      username: "System",
      message: `${username} joined the room.`,
    });
  });

  // Evento para um usuário sair de uma sala
  socket.on("leaveRoom", ({ username, room }: { username: string; room: string }) => {
    console.log(`${username} left room ${room}`);
    socket.leave(room);

    // Remove o participante da sala
    removeParticipant(room, username);

    const participants = getRoomParticipants(room);
    io.to(room).emit("updateParticipants", participants);

    io.to(room).emit("newMessageChat", {
      username: "System",
      message: `${username} left the room.`,
    });
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
  });
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
