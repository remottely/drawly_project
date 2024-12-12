import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import http from "http";
import { Server, Socket } from "socket.io";

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

// Objects
class Stroke {
  constructor(
    public points: Array<[number, number]>,
    public color: number,
    public size: number,
    public opacity: number,
    public strokeType: string,
    public filled: boolean
  ) { }
}

class RoomDrawing {
  private strokes: Stroke[] = [];
  private backupStrokes: Stroke[] = [];

  addStrokes(newStrokes: Stroke[]) {
    this.strokes.push(...newStrokes);
  }

  clear() {
    this.strokes = [];
    this.backupStrokes = [];
  }

  undo() {
    const lastStroke = this.strokes.pop();
    if (lastStroke) {
      this.backupStrokes.push(lastStroke);
    }
    return lastStroke;
  }

  redo() {
    const lastBackupStroke = this.backupStrokes.pop();
    if (lastBackupStroke) {
      this.strokes.push(lastBackupStroke);
    }
    return lastBackupStroke;
  }

  getStrokes() {
    return this.strokes;
  }
}

class Room {
  private participants: Set<string> = new Set();

  constructor(public name: string) { }

  addParticipant(username: string) {
    this.participants.add(username);
  }

  removeParticipant(username: string) {
    this.participants.delete(username);
  }

  getParticipants() {
    return Array.from(this.participants);
  }
}


// In-memory storage
const rooms: Record<string, Room> = {};
const roomDrawings: Record<string, RoomDrawing> = {};
const socketUserMap: Record<string, { username: string; room: string }> = {};

// Helper functions
const emitRoomList = () => io.emit("roomList", Object.keys(rooms));
const emitParticipantsUpdate = (roomName: string) =>
  io.to(roomName).emit("updateParticipants", rooms[roomName].getParticipants());

// Criar uma nova sala
const handleCreateRoom = (roomName: string) => {
  if (!rooms[roomName]) {
    rooms[roomName] = new Room(roomName);
    roomDrawings[roomName] = new RoomDrawing();
    console.log(`Room created: ${roomName}`);
    emitRoomList();
  }
};

// Adicionar participante
const handleJoinRoom = (socket: Socket, { username, room }: { username: string; room: string }) => {
  if (!rooms[room]) {
    console.log(`Room ${room} does not exist`);
    return;
  }

  const currentRoom = rooms[room];
  currentRoom.addParticipant(username);
  socket.join(room);

  socketUserMap[socket.id] = { username, room };
  io.to(room).emit("newMessageChat", { username, message: `joined the room.` });

  const roomDrawing = roomDrawings[room];
  if (roomDrawing) {
    socket.emit("draw", { strokes: roomDrawing.getStrokes() });
  }

  emitParticipantsUpdate(room);
  console.log(`${username} joined room ${room}`);
};


const handleLeaveRoom = (socket: Socket, { username, room }: { username: string; room: string }) => {
  console.log(`${username} left room ${room}`);

  io.to(room).emit("newMessageChat", { username, message: `left the room.` });
  rooms[room].removeParticipant(username);
  emitParticipantsUpdate(room);

  if (socketUserMap[socket.id]?.room === room) delete socketUserMap[socket.id];
  socket.leave(room);

  // Remover sala se estiver vazia
  const participants = rooms[room].getParticipants();
  if (participants.length === 0) {
    delete rooms[room];
    delete roomDrawings[room];
    console.log(`Room ${room} is now empty and has been removed.`);
    emitRoomList();
  }
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
  rooms[room].removeParticipant(username);

  emitParticipantsUpdate(room);

  const participants = rooms[room].getParticipants();
  io.to(room).emit("updateParticipants", participants);

  if (participants.length === 0) {
    delete rooms[room];
    delete roomDrawings[room];
    console.log(`Room ${room} is now empty and has been removed.`);
    emitRoomList();
  }
};

const handleDrawingActions = (socket: Socket) => {
  socket.on("draw", ({ room, strokes }: { room: string; strokes: Stroke[] }) => {
    const roomDrawing = roomDrawings[room];
    if (!roomDrawing) return;

    roomDrawing.addStrokes(strokes);
    io.to(room).emit("draw", { strokes });
  });

  socket.on("clearDraw", ({ room }: { room: string }) => {
    const roomDrawing = roomDrawings[room];
    if (!roomDrawing) return;

    roomDrawing.clear();
    io.to(room).emit("clearDraw");
  });

  socket.on("undoDraw", ({ room }: { room: string }) => {
    const roomDrawing = roomDrawings[room];
    if (!roomDrawing) return;

    roomDrawing.undo();
    io.to(room).emit("undoDraw");
  });

  socket.on("redoDraw", ({ room }: { room: string }) => {
    const roomDrawing = roomDrawings[room];
    if (!roomDrawing) return;

    roomDrawing.redo();
    io.to(room).emit("redoDraw");
  });
};


// Socket.IO setup
io.on("connection", (socket: Socket) => {
  console.log(`Client connected: ${socket.id}`);
  socket.emit("roomList", Object.keys(rooms));

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
