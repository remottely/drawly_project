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
  private turnQueue: string[] = [];
  private currentTurnIndex: number = 0;
  public currentWord: string | null = null;

  constructor(public name: string) { }

  addParticipant(username: string): void {
    this.participants.add(username);
    this.turnQueue.push(username);
  }

  removeParticipant(username: string): void {
    this.participants.delete(username);
    this.turnQueue = this.turnQueue.filter((user) => user !== username);
    if (this.currentTurnIndex >= this.turnQueue.length) {
      this.currentTurnIndex = 0;
    }
  }

  getParticipants(): string[] {
    return Array.from(this.participants);
  }

  getCurrentDrawer(): string {
    return this.turnQueue[this.currentTurnIndex];
  }

  advanceTurn(): void {
    this.currentTurnIndex = (this.currentTurnIndex + 1) % this.turnQueue.length;
  }
}

// Memory storage
interface SocketRoom {
  roomName: string;
}

interface SocketRoomDraw extends SocketRoom {
  strokes: Stroke[];
}

interface SocketRoomUser extends SocketRoom {
  username: string;
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
const minimumNumberOfPlayers = 2;
const wordsList = [
  "cat", "dog", "house", "car", "tree", "flower", "sun", "moon", "book", "plane",
  "river", "mountain", "beach", "fish", "bird", "computer", "phone", "chair", "table",
];

// Auxiliary functions
const emitRoomList = (): boolean => io.emit('roomList', Object.keys(rooms));
const emitParticipantsUpdate = (roomName: string): boolean =>
  io.to(roomName).emit('updateParticipants', rooms[roomName]?.getParticipants() || []);

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

    io.to(roomName).emit('messageChat:new', { username, message: "joined the room." });
    socket.emit('drawing:draw', { strokes: roomDrawings[roomName]?.getStrokes() });
    emitParticipantsUpdate(roomName);

    console.log(`${username} joined room ${roomName}`);
  },

  leave(socket: Socket, { username, roomName }: SocketRoomUser): void {
    console.log(`${username} left room ${roomName}`);
    io.to(roomName).emit('messageChat:new', { username, message: "left the room." });
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
    io.to(roomName).emit('messageChat:new', { username, message });
  },

  sendAnswer(socket: Socket, { username, roomName, answer }: SocketRoomUserAnswer): void {
    const room = rooms[roomName];
    if (!room) {
      console.error(`Room ${roomName} not found.`);
      socket.emit('error', { message: `Room ${roomName} does not exist.` });
      return;
    }

    const correctWord = room.currentWord;

    if (!correctWord) {
      console.error(`No word is being drawn in room ${roomName}.`);
      socket.emit('error', { message: `No word is currently being drawn.` });
      return;
    }

    const isCorrect = correctWord.toLowerCase() === answer.toLowerCase();

    io.to(roomName).emit('answerChat:new', { username, answer, isCorrect });
  },
};

const handleDrawingActions = {
  draw({ roomName, strokes }: SocketRoomDraw): void {
    roomDrawings[roomName]?.addStrokes(strokes);
    io.to(roomName).emit('drawing:draw', { strokes });
  },

  clear({ roomName }: SocketRoom): void {
    roomDrawings[roomName]?.clear();
    io.to(roomName).emit('drawing:clear');
  },

  undo({ roomName }: SocketRoom): void {
    roomDrawings[roomName]?.undo();
    io.to(roomName).emit('drawing:undo');
  },

  redo({ roomName }: SocketRoom): void {
    roomDrawings[roomName]?.redo();
    io.to(roomName).emit('drawing:redo');
  },
};

const handleTurnActions = {
  startTurnTimer(roomName: string, totalDuration: number = 60): void {
    const room = rooms[roomName];
    handleDrawingActions.clear({ roomName });

    if (!room) {
      console.error(`Room ${roomName} not found.`);
      return;
    }

    const participants = room.getParticipants();
    if (participants.length === 0) {
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

    io.to(roomName).emit('newTurn', {
      currentDrawer,
      word: wordToDraw,
      totalDuration: totalDuration * 1000,
    });

    console.log(`New turn started in room ${roomName}. Drawer: ${currentDrawer}, Word: ${wordToDraw}`);

    setTimeout(() => {
      room.advanceTurn();
      handleTurnActions.startTurnTimer(roomName, totalDuration);
    }, totalDuration * 1000);
  },
};

const handleGameActions = {
  startTurns(socket: Socket, { roomName }: SocketRoom): void {
    const room = rooms[roomName];
    if (!room) {
      console.error(`Room ${roomName} not found.`);
      socket.emit('error', { message: `Room ${roomName} does not exist.` });
      return;
    }

    if (room.getParticipants().length < minimumNumberOfPlayers) {
      console.error(`Not enough players in room ${roomName}. Minimum required: ${minimumNumberOfPlayers}`);
      socket.emit('error', { message: `Not enough players in the room. Minimum required: ${minimumNumberOfPlayers}.` });
      return;
    }

    console.log(`Turns manually started for room ${roomName}`);
    handleTurnActions.startTurnTimer(roomName, 60);
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

// Socket.IO Configuration
io.on('connection', (socket: Socket): void => {
  console.log(`Client connected: ${socket.id}`);
  socket.emit('roomList', Object.keys(rooms));

  socket.on('room:create', (data: SocketRoom) => handleRoomManagement.create(data));
  socket.on('room:join', (data: SocketRoomUser) => handleRoomManagement.join(socket, data));
  socket.on('room:leave', (data: SocketRoomUser) => handleRoomManagement.leave(socket, data));

  socket.on('answerChat:send', (data: SocketRoomUserAnswer) => handleChatActions.sendAnswer(socket, data));
  socket.on('messageChat:send', (data: SocketRoomUserMessage) => handleChatActions.sendMessage(data));

  socket.on('drawing:draw', (data) => handleDrawingActions.draw(data));
  socket.on('drawing:clear', (data) => handleDrawingActions.clear(data));
  socket.on('drawing:undo', (data) => handleDrawingActions.undo(data));
  socket.on('drawing:redo', (data) => handleDrawingActions.redo(data));

  socket.on('game:startTurns', (data) => handleGameActions.startTurns(socket, data));

  socket.on('disconnect', () => handleDisconnect(socket));
});

// Server startup
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
