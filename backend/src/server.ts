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

enum ErrorActionType {
  nothing = "nothing",
  retry = "retry",
  ignore = "ignore",
  log = "log",
  pop = "pop",
  dialog = "dialog",
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
  private participants: Set<Participant> = new Set();
  private turnQueue: Participant[] = [];
  private currentDrawerTurnIndex: number = 0;
  public currentWord: string | null = null;
  public turnCount: number = 0;

  constructor(public name: string) { }

  addParticipant(participant: Participant): void {
    this.participants.add(participant);
    this.turnQueue.push(participant);
  }

  removeParticipant(userId: string): void {
    const participantToRemove = Array.from(this.participants).find(
      (participant) => participant.userId === userId
    );
    if (participantToRemove) {
      this.participants.delete(participantToRemove);
      this.turnQueue = this.turnQueue.filter(
        (participant) => participant.userId !== userId
      );
    }
    if (this.currentDrawerTurnIndex >= this.turnQueue.length) {
      this.currentDrawerTurnIndex = 0;
    }
  }

  getParticipants(): Participant[] {
    return Array.from(this.participants);
  }

  getCurrentDrawer(): Participant | null {
    return this.turnQueue[this.currentDrawerTurnIndex] || null;
  }

  advanceTurn(): void {
    this.turnCount++;
    this.currentDrawerTurnIndex = (this.turnCount) % this.turnQueue.length;
  }
}

export class Message {
  constructor(
    public icon: string | null,
    public userId: string,
    public username: string,
    public text: string
  ) { }
}

export class Answer extends Message {
  constructor(
    icon: string | null,
    userId: string,
    username: string,
    text: string,
    public isCorrect: boolean
  ) {
    super(icon, userId, username, text);
  }
}

export class Participant {
  constructor(
    public userId: string,
    public username: string,
    public userAvatar: string | null,
    public isLogged: boolean
  ) { }
}

// DTOs
export class ErrorDTO {
  constructor(
    public message: string,
    public action: ErrorActionType,
  ) { }
}

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
    public userId: string,
    public username: string,
    public userAvatar: string | null,
    public isLogged: boolean
  ) {
    super(roomName);
  }
}

export class RoomUserMessageDTO extends RoomDTO {
  constructor(
    roomName: string,
    public userId: string,
    public username: string,
    public text: string
  ) {
    super(roomName);
  }
}

export class RoomUserAnswerDTO extends RoomDTO {
  constructor(
    roomName: string,
    public userId: string,
    public username: string,
    public text: string
  ) {
    super(roomName);
  }
}

// Global variables
const rooms: { [roomName: string]: Room } = {};
const roomDrawings: { [roomName: string]: Drawing } = {};
const roomUsers: { [socketId: string]: RoomUserDTO } = {};
const minNumberOfPlayers = 2;
// TODO(Kevin): Change back to 12
const maxmNumberOfPlayers = 3;

const wordsList = [
  "gato", "cachorro", "casa", "carro", "árvore", "flor", "sol", "lua", "livro", "avião",
  "rio", "montanha", "praia", "peixe", "pássaro", "computador", "telefone", "cadeira", "mesa",
  "namorados", "corda", "pular", "futebol", "bola", "cama", "travesseiro", "cobertor", "chave", "porta",
];

export class RoomManager {
  static emitRoomList(): boolean {
    return io.emit('room:all', {
      allRooms: Object.keys(rooms)
    });
  }

  static emitParticipantsUpdate(roomName: string): boolean {
    return io.to(roomName).emit('room:participants:update', {
      participants: rooms[roomName]?.getParticipants() || []
    });
  }

  static create({ roomName }: RoomDTO): void {
    if (!rooms[roomName]) {
      rooms[roomName] = new Room(roomName);
      roomDrawings[roomName] = new Drawing();
      console.log(`Room created: ${roomName}`);
      RoomManager.emitRoomList();
    }
  }

  static join(socket: Socket, { roomName, userId, username, userAvatar, isLogged }: RoomUserDTO, callback: any): void {
    if (!rooms[roomName]) {
      console.log(`Room ${roomName} does not exist`);
      return;
    }

    const currentRoom = rooms[roomName];

    if (currentRoom.getParticipants().length >= maxmNumberOfPlayers) {
      var message = `Room ${roomName} is full. Maximum ${maxmNumberOfPlayers} players allowed.`;
      console.error(message);
      socket.emit('error', new ErrorDTO(message, ErrorActionType.pop));
      callback({ success: false });
      return;
    }

    currentRoom.addParticipant(new Participant(userId, username, userAvatar, isLogged));

    socket.join(roomName);
    roomUsers[socket.id] = { roomName, userId, username, userAvatar, isLogged };

    io.to(roomName).emit('message:new', { icon: 'info', userId, username, text: "entrou" });
    socket.emit('drawing:draw', { strokes: roomDrawings[roomName]?.getStrokes() });
    RoomManager.emitParticipantsUpdate(roomName);


    console.log(`${userId} - ${username} joined room ${roomName}`);
    callback({ success: true, turn: currentRoom.turnCount });
  }

  static leave(socket: Socket, { roomName, userId, username }: RoomUserDTO): void {
    console.log(`${userId} - ${username} left room ${roomName}`);
    io.to(roomName).emit('message:new', { icon: 'info', userId, username, text: "saiu" });
    rooms[roomName]?.removeParticipant(userId);

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
}
export class AnswerActions {
  static send(socket: Socket, { roomName, userId, username, text }: RoomUserAnswerDTO): void {
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

    const isCorrect = correctWord.toLowerCase() === text.toLowerCase();
    const icon = isCorrect ? 'check' : null;

    io.to(roomName).emit('answer:new', new Answer(icon, userId, username, text, isCorrect));
  }
}

export class MessageActions {
  static send({ roomName, userId, username, text }: RoomUserMessageDTO): void {
    io.to(roomName).emit('message:new', new Message(null, userId, username, text));
  }
}

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
    room.advanceTurn();
    DrawingActions.clear({ roomName });

    if (!room) {
      console.error(`Room ${roomName} not found.`);
      return;
    }

    if (room.getParticipants().length === 0) {
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

    io.to(roomName).emit('turn:new', {
      turn: room.turnCount,
      currentDrawerUserId: currentDrawer.userId,
      currentDrawerUsername: currentDrawer.username,
      word: wordToDraw,
      totalDuration: totalDuration * 1000,
    });

    console.log(`New turn started in room ${roomName}. Drawer: ${currentDrawer.username}, Word: ${wordToDraw}`);

    setTimeout(() => {
      // room.advanceTurn();
      TurnManager.startTurnTimer(roomName, totalDuration);
    }, totalDuration * 1000);
  }
}

export class GameManager {
  static startTurns(socket: Socket, { roomName }: RoomDTO): void {
    const room = rooms[roomName];
    if (!room) {
      console.error(`Room ${roomName} not found.`);
      socket.emit('error', { message: `Room ${roomName} does not exist.` });
      return;
    }

    if (room.getParticipants().length < minNumberOfPlayers) {
      console.error(`Not enough players in room ${roomName}. Minimum required: ${minNumberOfPlayers}`);
      socket.emit('error', { message: `Not enough players in the room. Minimum required: ${minNumberOfPlayers}.` });
      return;
    }

    console.log(`Turns manually started for room ${roomName}`);
    // TODO(Kevin): PUT BACK: TurnManager.startTurnTimer(roomName, 60);
    TurnManager.startTurnTimer(roomName, 20);
  }
};

export function handleUserDisconnect(socket: Socket): void {
  const userInfo = roomUsers[socket.id];
  if (!userInfo) {
    // TODO(Kevin): do something here?
    console.log(`No user info found for socket ${socket.id}`);
    return;
  }

  const { roomName, userId, username } = userInfo;
  console.log(`User ${userId} - ${username} disconnected from room ${roomName}`);

  RoomManager.leave(socket, { roomName, userId, username, userAvatar: null, isLogged: false });
}

// Socket.IO Configuration
io.on('connection', (socket: Socket): void => {
  console.log(`Client connected: ${socket.id}`);
  socket.emit('room:all', {
    allRooms: Object.keys(rooms)
  });

  socket.on('room:create', (data: RoomDTO) => RoomManager.create(data));
  socket.on('room:join', (data: RoomUserDTO, callback: any) => RoomManager.join(socket, data, callback));
  socket.on('room:leave', (data: RoomUserDTO) => RoomManager.leave(socket, data));

  socket.on('drawing:draw', (data) => DrawingActions.draw(data));
  socket.on('drawing:clear', (data) => DrawingActions.clear(data));
  socket.on('drawing:undo', (data) => DrawingActions.undo(data));
  socket.on('drawing:redo', (data) => DrawingActions.redo(data));

  socket.on('answer:send', (data: RoomUserAnswerDTO) => AnswerActions.send(socket, data));

  socket.on('message:send', (data: RoomUserMessageDTO) => MessageActions.send(data));

  socket.on('game:turns:start', (data) => GameManager.startTurns(socket, data));

  socket.on('disconnect', () => handleUserDisconnect(socket));
});

// Server startup
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
