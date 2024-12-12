// Dependencies and initial configuration
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
interface Offset {
  x: number;
  y: number;
}

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
    public points: Offset[],
    public color: number,
    public size: number,
    public opacity: number,
    public strokeType: StrokeType,
    public filled: boolean
  ) { }
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

  constructor(public name: string) { }

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

// Memory storage
interface SocketRoom {
  roomName: string;
}

interface SocketRoomUser extends SocketRoom {
  username: string;
}

interface SocketRoomDraw extends SocketRoom {
  strokes: Stroke[];
}

interface SocketRoomUserMessage extends SocketRoomUser {
  message: string;
}

interface SocketRoomUserAnswer extends SocketRoomUser {
  answer: string;
}

interface RoomsMap {
  [roomName: string]: Room;
}

interface RoomDrawingsMap {
  [roomName: string]: RoomDrawing;
}

interface SocketUserMap {
  [socketId: string]: SocketRoomUser;
}

const rooms: RoomsMap = {};
const roomDrawings: RoomDrawingsMap = {};
const socketUserMap: SocketUserMap = {};

// Auxiliary functions
const emitRoomList = (): boolean => io.emit("roomList", Object.keys(rooms));
const emitParticipantsUpdate = (roomName: string): boolean =>
  io.to(roomName).emit("updateParticipants", rooms[roomName]?.getParticipants() || []);

const handleRoomManagement = {
  create({ roomName }: SocketRoom): void {
    if (!rooms[roomName]) {
      rooms[roomName] = new Room(roomName);
      roomDrawings[roomName] = new RoomDrawing();
      console.log(`Room created: ${roomName}`);
      emitRoomList();
    }
  },

  join(socket: Socket, { username, roomName }: SocketRoomUser): void {
    if (!rooms[roomName]) {
      console.log(`Room ${roomName} does not exist`);
      return;
    }

    const currentRoom = rooms[roomName];
    currentRoom.addParticipant(username);
    socket.join(roomName);
    socketUserMap[socket.id] = { username, roomName };

    io.to(roomName).emit("newMessageChat", { username, message: "joined the room." });
    socket.emit("draw", { strokes: roomDrawings[roomName]?.getStrokes() });
    emitParticipantsUpdate(roomName);

    console.log(`${username} joined room ${roomName}`);
  },

  leave(socket: Socket, { username, roomName }: SocketRoomUser): void {
    console.log(`${username} left room ${roomName}`);
    io.to(roomName).emit("newMessageChat", { username, message: "left the room." });
    rooms[roomName]?.removeParticipant(username);
    socket.leave(roomName);

    if (socketUserMap[socket.id]?.roomName === roomName) delete socketUserMap[socket.id];
    emitParticipantsUpdate(roomName);

    if (rooms[roomName]?.getParticipants().length === 0) {
      delete rooms[roomName];
      delete roomDrawings[roomName];
      console.log(`Room ${roomName} is now empty and has been removed.`);
      emitRoomList();
    }
  },
};

const handleChatActions = {
  sendMessage({ username, roomName, message }: SocketRoomUserMessage): void {
    io.to(roomName).emit("newMessageChat", { username, message });
  },

  sendAnswer({ username, roomName, answer }: SocketRoomUserAnswer): void {
    io.to(roomName).emit("newAnswerChat", { username, answer });
  },
};

const handleDrawingActions = {
  draw({ roomName, strokes }: SocketRoomDraw): void {
    roomDrawings[roomName]?.addStrokes(strokes);
    io.to(roomName).emit("draw", { strokes });
  },

  clear({ roomName }: SocketRoom): void {
    roomDrawings[roomName]?.clear();
    io.to(roomName).emit("clearDraw");
  },

  undo({ roomName }: SocketRoom): void {
    roomDrawings[roomName]?.undo();
    io.to(roomName).emit("undoDraw");
  },

  redo({ roomName }: SocketRoom): void {
    roomDrawings[roomName]?.redo();
    io.to(roomName).emit("redoDraw");
  },
};

const handleDisconnect = (socket: Socket): void => {
  const userInfo = socketUserMap[socket.id];
  if (!userInfo) {
    console.log(`No user info found for socket ${socket.id}`);
    return;
  }

  const { username, roomName } = userInfo;
  console.log(`User ${username} disconnected from room ${roomName}`);

  handleRoomManagement.leave(socket, { username, roomName });
};

// Configuração do Socket.IO
io.on("connection", (socket: Socket): void => {
  console.log(`Client connected: ${socket.id}`);
  socket.emit("roomList", Object.keys(rooms));

  socket.on("createRoom", (data: SocketRoom) => handleRoomManagement.create(data));
  socket.on("joinRoom", (data: SocketRoomUser) => handleRoomManagement.join(socket, data));
  socket.on("leaveRoom", (data: SocketRoomUser) => handleRoomManagement.leave(socket, data));

  socket.on("sendMessageChat", (data: SocketRoomUserMessage) => handleChatActions.sendMessage(data));
  socket.on("sendAnswerChat", (data: SocketRoomUserAnswer) => handleChatActions.sendAnswer(data));

  socket.on("draw", (data) => handleDrawingActions.draw(data));
  socket.on("clearDraw", (data) => handleDrawingActions.clear(data));
  socket.on("undoDraw", (data) => handleDrawingActions.undo(data));
  socket.on("redoDraw", (data) => handleDrawingActions.redo(data));

  socket.on("disconnect", () => handleDisconnect(socket));
});

// Server startup
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
