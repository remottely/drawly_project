// Dependências e configuração inicial
import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import http from "http";
import { Server, Socket } from "socket.io";

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });
const PORT = process.env.PORT || 5555;

// Middleware
app.use(cors());
app.use(express.json());

// Classes
type Point = { x: number; y: number }; // Representação do Offset

enum StrokeType {
  normal = "normal",
  eraser = "eraser",
  line = "line",
  polygon = "polygon",
  square = "square",
  circle = "circle",
}

class Stroke {
  constructor(
    public points: Point[],
    public color: number,
    public size: number,
    public opacity: number,
    public strokeType: StrokeType,
    public filled: boolean
  ) {}
}

class RoomDrawing {
  private strokes: Stroke[] = [];
  private backupStrokes: Stroke[] = [];

  addStrokes(newStrokes: Stroke[]): void {
    this.strokes.push(...newStrokes);
  }

  clear(): void {
    this.strokes = [];
    this.backupStrokes = [];
  }

  undo(): Stroke | undefined {
    const lastStroke = this.strokes.pop();
    if (lastStroke) this.backupStrokes.push(lastStroke);
    return lastStroke;
  }

  redo(): Stroke | undefined {
    const lastBackupStroke = this.backupStrokes.pop();
    if (lastBackupStroke) this.strokes.push(lastBackupStroke);
    return lastBackupStroke;
  }

  getStrokes(): Stroke[] {
    return this.strokes;
  }
}

class Room {
  private participants: Set<string> = new Set();

  constructor(public name: string) {}

  addParticipant(username: string): void {
    this.participants.add(username);
  }

  removeParticipant(username: string): void {
    this.participants.delete(username);
  }

  getParticipants(): string[] {
    return Array.from(this.participants);
  }
}

// Armazenamento em memória
interface SocketUser {
  username: string;
  room: string;
}

const rooms: Record<string, Room> = {};
const roomDrawings: Record<string, RoomDrawing> = {};
const socketUserMap: Record<string, SocketUser> = {};

// Funções auxiliares
const emitRoomList = (): boolean => io.emit("roomList", Object.keys(rooms));
const emitParticipantsUpdate = (roomName: string): boolean =>
  io.to(roomName).emit("updateParticipants", rooms[roomName]?.getParticipants() || []);

const handleRoomManagement = {
  create(roomName: string): void {
    if (!rooms[roomName]) {
      rooms[roomName] = new Room(roomName);
      roomDrawings[roomName] = new RoomDrawing();
      console.log(`Room created: ${roomName}`);
      emitRoomList();
    }
  },

  join(socket: Socket, { username, room }: SocketUser): void {
    if (!rooms[room]) {
      console.log(`Room ${room} does not exist`);
      return;
    }

    const currentRoom = rooms[room];
    currentRoom.addParticipant(username);
    socket.join(room);
    socketUserMap[socket.id] = { username, room };

    io.to(room).emit("newMessageChat", { username, message: "joined the room." });
    socket.emit("draw", { strokes: roomDrawings[room]?.getStrokes() });
    emitParticipantsUpdate(room);

    console.log(`${username} joined room ${room}`);
  },

  leave(socket: Socket, { username, room }: SocketUser): void {
    console.log(`${username} left room ${room}`);
    io.to(room).emit("newMessageChat", { username, message: "left the room." });
    rooms[room]?.removeParticipant(username);
    socket.leave(room);

    if (socketUserMap[socket.id]?.room === room) delete socketUserMap[socket.id];
    emitParticipantsUpdate(room);

    if (rooms[room]?.getParticipants().length === 0) {
      delete rooms[room];
      delete roomDrawings[room];
      console.log(`Room ${room} is now empty and has been removed.`);
      emitRoomList();
    }
  },
};

const handleDrawingActions = (socket: Socket): void => {
  socket.on("draw", ({ room, strokes }: { room: string; strokes: Stroke[] }) => {
    roomDrawings[room]?.addStrokes(strokes);
    io.to(room).emit("draw", { strokes });
  });

  socket.on("clearDraw", ({ room }: { room: string }) => {
    roomDrawings[room]?.clear();
    io.to(room).emit("clearDraw");
  });

  socket.on("undoDraw", ({ room }: { room: string }) => {
    roomDrawings[room]?.undo();
    io.to(room).emit("undoDraw");
  });

  socket.on("redoDraw", ({ room }: { room: string }) => {
    roomDrawings[room]?.redo();
    io.to(room).emit("redoDraw");
  });
};

const handleDisconnect = (socket: Socket): void => {
  const userInfo = socketUserMap[socket.id];
  if (!userInfo) {
    console.log(`No user info found for socket ${socket.id}`);
    return;
  }

  const { username, room } = userInfo;
  console.log(`User ${username} disconnected from room ${room}`);

  handleRoomManagement.leave(socket, { username, room });
};

// Configuração do Socket.IO
io.on("connection", (socket: Socket): void => {
  console.log(`Client connected: ${socket.id}`);
  socket.emit("roomList", Object.keys(rooms));

  socket.on("createRoom", (roomName: string) => handleRoomManagement.create(roomName));
  socket.on("joinRoom", (data: SocketUser) => handleRoomManagement.join(socket, data));
  socket.on("leaveRoom", (data: SocketUser) => handleRoomManagement.leave(socket, data));

  socket.on("sendMessageChat", ({ username, room, message }: { username: string; room: string; message: string }) =>
    io.to(room).emit("newMessageChat", { username, message })
  );

  socket.on("sendAnswerChat", ({ username, room, answer }: { username: string; room: string; answer: string }) =>
    io.to(room).emit("newAnswerChat", { username, answer })
  );

  handleDrawingActions(socket);
  socket.on("disconnect", () => handleDisconnect(socket));
});

// Inicialização do servidor
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
