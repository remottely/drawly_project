import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import http from "http";
import { Server, Socket } from "socket.io";
import { createRoom, getRoomParticipants, removeParticipant } from "./rooms/roomManager";

dotenv.config();

// Express and Socket.IO setup
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Allow connections from any origin (adjust for production)
  },
});

const PORT = process.env.PORT || 5555;

app.use(cors());
app.use(express.json());

// Types
type Stroke = {
  points: Array<[number, number]>;
  color: number;
  size: number;
  opacity: number;
  strokeType: string;
  filled: boolean;
};

// In-memory storage
const roomDrawings: Record<string, Stroke[]> = {};
const backupRoomDrawings: Record<string, Stroke[]> = {};
const availableRooms = new Set<string>();
const socketUserMap: Record<string, { username: string; room: string }> = {};

// Socket.IO event handlers
io.on("connection", (socket: Socket) => {
  console.log(`Client connected: ${socket.id}`);

  // Emit available rooms to the newly connected client
  socket.emit("roomList", Array.from(availableRooms));

  socket.on("createRoom", (roomName: string) => {
    if (!availableRooms.has(roomName)) {
      availableRooms.add(roomName);
      console.log(`Room created: ${roomName}`);
      io.emit("roomList", Array.from(availableRooms));
    }
  });

  socket.on("joinRoom", ({ username, room }: { username: string; room: string }) => {
    if (!availableRooms.has(room)) {
      console.log(`Room ${room} does not exist`);
      return;
    }

    socket.join(room);
    createRoom(room, username);
    socketUserMap[socket.id] = { username, room };

    // Send accumulated drawing to the new client
    if (roomDrawings[room]) {
      console.log(`Sending full drawing to client ${socket.id} for room ${room}`);
      socket.emit("draw", { strokes: roomDrawings[room] });
    } else {
      console.log(`No drawing available for room ${room}`);
    }

    const participants = getRoomParticipants(room);
    io.to(room).emit("updateParticipants", participants);

    console.log(`${username} joined room ${room}`);
    io.to(room).emit("newMessageChat", { username, message: `joined the room.` });
  });

  socket.on("leaveRoom", ({ username, room }: { username: string; room: string }) => {
    console.log(`${username} left room ${room}`);

    io.to(room).emit("newMessageChat", { username, message: `left the room.` });
    removeParticipant(room, username, availableRooms);

    const participants = getRoomParticipants(room);
    io.to(room).emit("updateParticipants", participants);

    if (socketUserMap[socket.id]?.room === room) {
      delete socketUserMap[socket.id];
    }
    socket.leave(room);
  });

  socket.on("sendMessageChat", ({ username, room, message }: { username: string; room: string; message: string }) => {
    io.to(room).emit("newMessageChat", { username, message });
  });

  socket.on("sendAnswerChat", ({ username, room, answer }: { username: string; room: string; answer: string }) => {
    io.to(room).emit("newAnswerChat", { username, answer });
  });

  socket.on("draw", ({ room, strokes }: { room: string; strokes: Stroke[] }) => {
    console.log(`Drawing received for room ${room}:`, strokes);

    if (!roomDrawings[room]) roomDrawings[room] = [];
    if (!backupRoomDrawings[room]) backupRoomDrawings[room] = [];

    roomDrawings[room].push(...strokes);
    io.to(room).emit("draw", { strokes });

    console.log(`Drawing broadcasted to room ${room}:`, strokes);
  });

  socket.on("clearDraw", ({ room }: { room: string }) => {
    console.log(`Clear draw received for room ${room}`);
    roomDrawings[room] = [];
    backupRoomDrawings[room] = [];
    io.to(room).emit("clearDraw");
  });

  socket.on("undoDraw", ({ room }: { room: string }) => {
    console.log(`Undo draw received for room ${room}`);
    const poppedValue = roomDrawings[room]?.pop();
    if (poppedValue) backupRoomDrawings[room].push(poppedValue);
    io.to(room).emit("undoDraw");
  });

  socket.on("redoDraw", ({ room }: { room: string }) => {
    console.log(`Redo draw received for room ${room}`);
    const poppedValue = backupRoomDrawings[room]?.pop();
    if (poppedValue) roomDrawings[room].push(poppedValue);
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
      removeParticipant(room, username, availableRooms);

      const participants = getRoomParticipants(room);
      io.to(room).emit("updateParticipants", participants);

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

// Start server
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
