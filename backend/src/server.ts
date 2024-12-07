import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import http from "http";
import { Server, Socket } from "socket.io";
import { createRoom, getRoomParticipants } from "./rooms/roomManager";

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Allow connections from any source (change for production)
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

// Map to store drawing history for each room
const roomDrawings: Record<string, Stroke[]> = {};
const backupRoomDrawings: Record<string, Stroke[]> = {};

// Set to manage the list of available rooms
const availableRooms = new Set<string>();

io.on("connection", (socket: Socket) => {
  console.log(`Client connected: ${socket.id}`);

  // Send the list of available rooms to the newly connected client
  socket.emit("roomList", Array.from(availableRooms));

  // Event to create a new room
  socket.on("createRoom", (roomName: string) => {
    if (!availableRooms.has(roomName)) {
      availableRooms.add(roomName);
      console.log(`Room created: ${roomName}`);
      io.emit("roomList", Array.from(availableRooms)); // Broadcast updated room list to all clients
    }
  });

  // Event when a user joins a room
  socket.on("joinRoom", ({ username, room }: { username: string; room: string }) => {
    if (!availableRooms.has(room)) {
      console.log(`Room ${room} does not exist`);
      return;
    }

    socket.join(room);
    createRoom(room, username);

    // Send the accumulated drawing to the client who just joined
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

  // Event for leaving a room
  socket.on("leaveRoom", ({ username, room }: { username: string; room: string }) => {
    console.log(`${username} left room ${room}`);
    socket.leave(room);

    io.to(room).emit("newMessageChat", {
      username: "System",
      message: `${username} left the room.`,
    });

    const participants = getRoomParticipants(room);
    io.to(room).emit("updateParticipants", participants);
  });

  // Event to handle sending messages
  socket.on("sendMessageChat", ({ username, room, message }: { username: string; room: string; message: string }) => {
    io.to(room).emit("newMessageChat", { username, message });
  });

  socket.on("sendAnswerChat", ({ username, room, answer }: { username: string; room: string; answer: string }) => {
    io.to(room).emit("newAnswerChat", { username, answer });
  });

  // Event to handle drawing data
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


  socket.on("clearDraw", ({ room }: { room: string }) => {
    console.log(`Clear draw received for room ${room}`);

    roomDrawings[room] = [];
    backupRoomDrawings[room] = [];
    io.to(room).emit("clearDraw");
    console.log(`Clear draw broadcasted to room ${room}`);
  });

  socket.on("undoDraw", ({ room }: { room: string }) => {
    console.log(`Undo draw received for room ${room}`);

    const poppedValue = roomDrawings[room].pop();
    if (poppedValue) backupRoomDrawings[room].push(poppedValue);
    io.to(room).emit("undoDraw");

    console.log(`Undo draw broadcasted to room ${room}`);
  });

  socket.on("redoDraw", ({ room }: { room: string }) => {
    console.log(`Redo draw received for room ${room}`);

    const poppedValue = backupRoomDrawings[room].pop();
    if (poppedValue) roomDrawings[room].push(poppedValue);
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
