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
export class Offset {
  constructor(
    public dx: number,
    public dy: number,
  ) { }
}

enum StrokeType {
  normal = "normal",
  eraser = "eraser",
  line = "line",
  polygon = "polygon",
  square = "square",
  circle = "circle",
}

export class Stroke {
  constructor(
    public points: Offset[],
    public color: number,
    public size: number,
    public opacity: number,
    public strokeType: StrokeType,
    public filled: boolean
  ) { }
}

export class Drawing {
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

export class Room {
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

export class Message {
  constructor(
    public icon: string | null,
    public username: string,
    public text: string
  ) { }
}

export class Answer extends Message {
  constructor(
    icon: string | null,
    username: string,
    text: string,
    public isCorrect: boolean
  ) {
    super(icon, username, text);
  }
}

// DTOs
export class RoomDTO {
  constructor(
    public roomName: string
  ) { }
}

export class RoomDrawingDTO extends RoomDTO {
  constructor(
    roomName: string,
    public strokes: Stroke[]
  ) {
    super(roomName);
  }
}

export class RoomUserDTO extends RoomDTO {
  constructor(
    roomName: string,
    public username: string
  ) {
    super(roomName);
  }
}

export class RoomUserMessageDTO extends RoomUserDTO {
  constructor(
    roomName: string,
    username: string,
    public text: string
  ) {
    super(roomName, username);
  }
}

export class RoomUserAnswerDTO extends RoomUserDTO {
  constructor(
    roomName: string,
    username: string,
    public text: string
  ) {
    super(roomName, username);
  }
}

// Global variables
const rooms: { [roomName: string]: Room } = {};
const roomDrawings: { [roomName: string]: Drawing } = {};
const roomUsers: { [socketId: string]: RoomUserDTO } = {};
const minimumNumberOfPlayers = 2;
const wordsList = [
  "cat", "dog", "house", "car", "tree", "flower", "sun", "moon", "book", "plane",
  "river", "mountain", "beach", "fish", "bird", "computer", "phone", "chair", "table",
];

export class RoomManager {
  static emitRoomList(): boolean {
    return io.emit('roomList', Object.keys(rooms));
  }

  static emitParticipantsUpdate(roomName: string): boolean {
    return io.to(roomName).emit('updateParticipants', rooms[roomName]?.getParticipants() || []);
  }


  static create({ roomName }: RoomDTO): void {
    if (!rooms[roomName]) {
      rooms[roomName] = new Room(roomName);
      roomDrawings[roomName] = new Drawing();
      console.log(`Room created: ${roomName}`);
      RoomManager.emitRoomList();
    }
  }

  static join(socket: Socket, { roomName, username }: RoomUserDTO): void {
    if (!rooms[roomName]) {
      console.log(`Room ${roomName} does not exist`);
      return;
    }

    const currentRoom = rooms[roomName];
    currentRoom.addParticipant(username);
    socket.join(roomName);
    roomUsers[socket.id] = { roomName, username };

    io.to(roomName).emit('message:new', { icon: 'info', username, text: "joined" });
    socket.emit('drawing:draw', { strokes: roomDrawings[roomName]?.getStrokes() });
    RoomManager.emitParticipantsUpdate(roomName);

    console.log(`${username} joined room ${roomName}`);
  }

  static leave(socket: Socket, { username, roomName }: RoomUserDTO): void {
    console.log(`${username} left room ${roomName}`);
    io.to(roomName).emit('message:new', { icon: 'info', username, text: "left" });
    rooms[roomName]?.removeParticipant(username);
    socket.leave(roomName);

    if (roomUsers[socket.id]?.roomName === roomName) delete roomUsers[socket.id];
    RoomManager.emitParticipantsUpdate(roomName);

    if (rooms[roomName]?.getParticipants().length === 0) {
      delete rooms[roomName];
      delete roomDrawings[roomName];
      console.log(`Room ${roomName} is now empty and has been removed.`);
      RoomManager.emitRoomList();
    }
  }
};

export class AnswerActions {
  static send(socket: Socket, { roomName, username, text }: RoomUserAnswerDTO): void {
    const room = rooms[roomName];
    const answer = text;
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
    const icon = isCorrect ? 'check' : null;

    io.to(roomName).emit('answer:new', new Answer(icon, username, answer, isCorrect));
  }
};

export class MessageActions {
  static send({ roomName, username, text }: RoomUserMessageDTO): void {
    io.to(roomName).emit('message:new', new Message(null, username, text));
  }
};

export class DrawingActions {
  static draw({ roomName, strokes }: RoomDrawingDTO): void {
    roomDrawings[roomName]?.addStrokes(strokes);
    io.to(roomName).emit('drawing:draw', { strokes });
  }

  static clear({ roomName }: RoomDTO): void {
    roomDrawings[roomName]?.clear();
    io.to(roomName).emit('drawing:clear');
  }

  static undo({ roomName }: RoomDTO): void {
    roomDrawings[roomName]?.undo();
    io.to(roomName).emit('drawing:undo');
  }

  static redo({ roomName }: RoomDTO): void {
    roomDrawings[roomName]?.redo();
    io.to(roomName).emit('drawing:redo');
  }
};

export class TurnManager {
  static startTurnTimer(roomName: string, totalDuration: number = 60): void {
    const room = rooms[roomName];
    DrawingActions.clear({ roomName });

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
      TurnManager.startTurnTimer(roomName, totalDuration);
    }, totalDuration * 1000);
  }
};

export class GameManager {
  static startTurns(socket: Socket, { roomName }: RoomDTO): void {
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
    TurnManager.startTurnTimer(roomName, 60);
  }
};

export function handleUserDisconnect(socket: Socket): void {
  const userInfo = roomUsers[socket.id];
  if (!userInfo) {
    console.log(`No user info found for socket ${socket.id}`);
    return;
  }

  const { roomName, username } = userInfo;
  console.log(`User ${username} disconnected from room ${roomName}`);

  RoomManager.leave(socket, { roomName, username });
};

// Socket.IO Configuration
io.on('connection', (socket: Socket): void => {
  console.log(`Client connected: ${socket.id}`);
  socket.emit('roomList', Object.keys(rooms));

  socket.on('room:create', (data: RoomDTO) => RoomManager.create(data));
  socket.on('room:join', (data: RoomUserDTO) => RoomManager.join(socket, data));
  socket.on('room:leave', (data: RoomUserDTO) => RoomManager.leave(socket, data));

  socket.on('drawing:draw', (data) => DrawingActions.draw(data));
  socket.on('drawing:clear', (data) => DrawingActions.clear(data));
  socket.on('drawing:undo', (data) => DrawingActions.undo(data));
  socket.on('drawing:redo', (data) => DrawingActions.redo(data));

  socket.on('answer:send', (data: RoomUserAnswerDTO) => AnswerActions.send(socket, data));

  socket.on('message:send', (data: RoomUserMessageDTO) => MessageActions.send(data));

  socket.on('game:startTurns', (data) => GameManager.startTurns(socket, data));

  socket.on('disconnect', () => handleUserDisconnect(socket));
});

// Server startup
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
