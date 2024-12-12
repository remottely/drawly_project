import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import http from "http";
import { Server, Socket } from "socket.io";
import { createRoom, getRoomParticipants, removeParticipant } from "./rooms/roomManager";

dotenv.config();

// Setup
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" }, // Permitir conexões de qualquer origem
});
const PORT = process.env.PORT || 5555;

// Middleware
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

// Helper functions
const emitRoomList = () => io.emit("roomList", Array.from(availableRooms));
const emitParticipantsUpdate = (room: string) =>
  io.to(room).emit("updateParticipants", getRoomParticipants(room));

// Event Handlers
const handleCreateRoom = (roomName: string) => {
  if (!availableRooms.has(roomName)) {
    availableRooms.add(roomName);
    console.log(`Room created: ${roomName}`);
    emitRoomList();
  }
};

const handleJoinRoom = (socket: Socket, { username, room }: { username: string; room: string }) => {
  if (!availableRooms.has(room)) {
    console.log(`Room ${room} does not exist`);
    return;
  }

  socket.join(room);
  createRoom(room, username);
  socketUserMap[socket.id] = { username, room };

  io.to(room).emit("newMessageChat", { username, message: `joined the room.` });

  if (roomDrawings[room]) {
    socket.emit("draw", { strokes: roomDrawings[room] });
  }

  emitParticipantsUpdate(room);

  console.log(`${username} joined room ${room}`);
};

const handleLeaveRoom = (socket: Socket, { username, room }: { username: string; room: string }) => {
  console.log(`${username} left room ${room}`);

  io.to(room).emit("newMessageChat", { username, message: `left the room.` });
  removeParticipant(room, username, availableRooms);

  emitParticipantsUpdate(room);

  if (socketUserMap[socket.id]?.room === room) delete socketUserMap[socket.id];
  socket.leave(room);
};

const handleDisconnect = (socket: Socket) => {
  const userInfo = socketUserMap[socket.id];
  if (!userInfo) {
    console.log(`No user info found for socket ${socket.id}`);
    return;
  }

  const { username, room } = userInfo;
  console.log(`User ${username} disconnected from room ${room}`);

  io.to(room).emit("newMessageChat", { username, message: `disconnected.` });
  delete socketUserMap[socket.id];
  removeParticipant(room, username, availableRooms);

  emitParticipantsUpdate(room);
  
  const participants = getRoomParticipants(room);
  io.to(room).emit("updateParticipants", participants);
  
  if (participants.length === 0) {
    availableRooms.delete(room);
    console.log(`Room ${room} is now empty and has been removed.`);
    emitRoomList();
  }
};

const handleDrawingActions = (socket: Socket) => {
  socket.on("draw", ({ room, strokes }: { room: string; strokes: Stroke[] }) => {
    roomDrawings[room] = roomDrawings[room] || [];
    backupRoomDrawings[room] = backupRoomDrawings[room] || [];
    roomDrawings[room].push(...strokes);
    io.to(room).emit("draw", { strokes });
  });

  socket.on("clearDraw", ({ room }: { room: string }) => {
    roomDrawings[room] = [];
    backupRoomDrawings[room] = [];
    io.to(room).emit("clearDraw");
  });

  socket.on("undoDraw", ({ room }: { room: string }) => {
    const poppedValue = roomDrawings[room]?.pop();
    if (poppedValue) backupRoomDrawings[room].push(poppedValue);
    io.to(room).emit("undoDraw");
  });

  socket.on("redoDraw", ({ room }: { room: string }) => {
    const poppedValue = backupRoomDrawings[room]?.pop();
    if (poppedValue) roomDrawings[room].push(poppedValue);
    io.to(room).emit("redoDraw");
  });
};

// Socket.IO setup
io.on("connection", (socket: Socket) => {
  console.log(`Client connected: ${socket.id}`);
  socket.emit("roomList", Array.from(availableRooms));

  socket.on("createRoom", (roomName: string) => handleCreateRoom(roomName));
  socket.on("joinRoom", (data) => handleJoinRoom(socket, data));
  socket.on("leaveRoom", (data) => handleLeaveRoom(socket, data));
  socket.on("sendMessageChat", ({ username, room, message }) =>
    io.to(room).emit("newMessageChat", { username, message })
  );
  socket.on("sendAnswerChat", ({ username, room, answer }) =>
    io.to(room).emit("newAnswerChat", { username, answer })
  );
  handleDrawingActions(socket);
  socket.on("disconnect", () => handleDisconnect(socket));
});

// Start server
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
