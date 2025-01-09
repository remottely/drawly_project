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

  addStroke(newStroke: Stroke): void {
    this.strokes.push(newStroke);
  }

  addStrokeLastPoints(points: Offset[]): void {
    if (this.strokes.length > 0) {
      const lastStroke = this.strokes[this.strokes.length - 1];
      lastStroke.points.push(...points);
    } else {
      console.error('No strokes available to add points to.');
    }
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

  ///
  private participantsWhoAnsweredCorrectly: Set<string> = new Set();

  participantCorrectAnswer(userId: string): void {
    this.participantsWhoAnsweredCorrectly.add(userId);
  }

  hasEveryoneAnsweredCorrectly(): boolean {
    const nonDrawerConnectedParticipants = this.getParticipants().filter(
      (participant) =>
        participant.userId !== this.getCurrentDrawer()?.userId && participant.isConnected
    );
    return nonDrawerConnectedParticipants.every((participant) =>
      this.participantsWhoAnsweredCorrectly.has(participant.userId)
    );
  }


  resetCorrectAnswers(): void {
    this.participantsWhoAnsweredCorrectly.clear();
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

export class Turn {
  constructor(
    public word: string,
    public turn: number,
    public totalDuration: number,
    public currentDrawerUserId: string,
    public currentDrawerUsername: string,
  ) { }
}

export class Participant {
  constructor(
    public userId: string,
    public username: string,
    public userAvatar: string | null,
    public isLogged: boolean,
    public isConnected: boolean = true,
    public score: number = 0
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

export class RoomDrawingStartStrokeDTO extends RoomDTO {
  constructor(
    roomName: string,
    public stroke: Stroke
  ) {
    super(roomName);
  }
}

export class RoomDrawingStrokeLastPointsDTO extends RoomDTO {
  constructor(
    roomName: string,
    public strokeLastPoints: Offset[]
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

    const existingParticipant = currentRoom.getParticipants().find((p) => p.userId === userId);
    if (existingParticipant) {
      // Restaura o estado do participante
      existingParticipant.isConnected = true; // Marca como reconectado
      console.log(`${userId} - ${username} reconnected to room ${roomName}`);
    } else if (currentRoom.getParticipants().length < maxmNumberOfPlayers) {
      // Novo participante entra
      currentRoom.addParticipant(new Participant(userId, username, userAvatar, isLogged, true));
      console.log(`${userId} - ${username} joined room ${roomName}`);
    } else {
      const message = `Room ${roomName} is full. Maximum ${maxmNumberOfPlayers} players allowed.`;
      console.error(message);
      socket.emit('error', new ErrorDTO(message, ErrorActionType.pop));
      callback({ success: false });
      return;
    }

    socket.join(roomName);
    roomUsers[socket.id] = { roomName, userId, username, userAvatar, isLogged };

    MessageChatActions.message(roomName, new Message('info', userId, username, "entrou"));

    // Sincroniza o estado do jogo com o participante reconectado
    socket.emit('drawing:stroke:all', { strokes: roomDrawings[roomName]?.getStrokes() });
    RoomManager.emitParticipantsUpdate(roomName);

    callback({ success: true, turn: currentRoom.turnCount });
  }

  static leave(socket: Socket, { roomName, userId, username }: RoomUserDTO): void {
    console.log(`${userId} - ${username} left room ${roomName}`);
    MessageChatActions.message(roomName, new Message('info', userId, username, "saiu"));
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

export class AnswerChatActions {
  static guess(socket: Socket, { roomName, userId, username, text }: RoomUserAnswerDTO): void {
    const room = rooms[roomName];
    if (!room) {
      const message = `Room ${roomName} does not exist.`;
      console.error(message);
      socket.emit('error', new ErrorDTO(message, ErrorActionType.nothing));
      return;
    }

    const correctWord = room.currentWord;

    if (!correctWord) {
      const message = `No word is currently being drawn.`;
      console.error(`${message} in room ${roomName}.`);
      socket.emit('error', new ErrorDTO(message, ErrorActionType.nothing));
      return;
    }

    const isCorrect = correctWord.toLowerCase() === text.toLowerCase();
    const icon = isCorrect ? 'check' : null;

    if (isCorrect) {
      const participant = room.getParticipants().find((p) => p.userId === userId);
      const drawer = room.getCurrentDrawer();

      if (participant) {
        const timeLeft = room.turnCount; // Exemplo: use o tempo restante no turno para calcular pontos
        const points = Math.max(100 - (timeLeft * 10), 10); // Mais pontos para respostas rápidas
        participant.score += points;

        if (drawer) {
          const drawerPoints = 20; // Pontos fixos por jogador que acerta
          drawer.score += drawerPoints;
        }

        console.log(`${username} acertou! Ganhou ${points} pontos.`);
        room.participantCorrectAnswer(userId);

        // Verificar se todos acertaram
        if (room.hasEveryoneAnsweredCorrectly()) {
          console.log(`All participants in room ${roomName} have answered correctly. Advancing turn.`);
          room.resetCorrectAnswers();
          TurnManager.startTurnTimer(roomName, 60); // Avança o turno
          return;
        }
      }
    }

    io.to(roomName).emit('chat:answer:result', new Answer(icon, userId, username, text, isCorrect));
  }
}

export class MessageChatActions {
  static message(roomName: string, message: Message): void {
    io.to(roomName).emit('chat:message', message);
  }
}

export class DrawingActions {
  static strokeStart({ roomName, stroke }: RoomDrawingStartStrokeDTO): void {
    roomDrawings[roomName]?.addStroke(stroke);
    io.to(roomName).emit('drawing:stroke:start', { stroke });
  }

  static strokeLastPoints({ roomName, strokeLastPoints }: RoomDrawingStrokeLastPointsDTO): void {
    roomDrawings[roomName]?.addStrokeLastPoints(strokeLastPoints);
    io.to(roomName).emit('drawing:stroke:lastPoints', { strokeLastPoints });
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
    if (!room) {
      console.error(`Room ${roomName} not found.`);
      return;
    }

    room.advanceTurn();
    room.resetCorrectAnswers();
    DrawingActions.clear({ roomName });

    const currentDrawer = room.getCurrentDrawer();
    if (!currentDrawer) {
      console.error(`Failed to get the current drawer in room ${roomName}`);
      return;
    }

    const wordToDraw = wordsList[Math.floor(Math.random() * wordsList.length)];
    room.currentWord = wordToDraw;

    io.to(roomName).emit('game:turn:new', new Turn(
      wordToDraw,
      room.turnCount,
      totalDuration * 1000,
      currentDrawer.userId,
      currentDrawer.username,
    ));

    RoomManager.emitParticipantsUpdate(roomName); // Atualiza a pontuação ao iniciar o turno

    console.log(`New turn started in room ${roomName}. Drawer: ${currentDrawer.username}, Word: ${wordToDraw}`);

    setTimeout(() => {
      TurnManager.startTurnTimer(roomName, totalDuration);
    }, totalDuration * 1000);
  }
}

export class GameManager {
  static startTurns(socket: Socket, { roomName }: RoomDTO): void {
    const room = rooms[roomName];
    if (!room) {
      const message = `Room ${roomName} does not exist.`;
      console.error(message);
      socket.emit('error', new ErrorDTO(message, ErrorActionType.nothing));
      return;
    }

    if (room.getParticipants().length < minNumberOfPlayers) {
      const message = `Not enough players in the room ${roomName}. Minimum required: ${minNumberOfPlayers}.`;
      console.error(message);
      socket.emit('error', new ErrorDTO(message, ErrorActionType.nothing));
      return;
    }

    console.log(`Turns manually started for room ${roomName}`);
    // TODO(Kevin): PUT BACK: TurnManager.startTurnTimer(roomName, 60);
    TurnManager.startTurnTimer(roomName, 60);
  }

  static showRanking(roomName: string): void {
    const room = rooms[roomName];
    if (!room) {
      console.error(`Room ${roomName} does not exist.`);
      return;
    }

    const ranking = room.getParticipants()
      .sort((a, b) => b.score - a.score) // Ordena por pontuação decrescente
      .map((p, index) => ({
        rank: index + 1,
        username: p.username,
        score: p.score,
      }));

    io.to(roomName).emit('game:ranking', { ranking });
    console.log(`Ranking for room ${roomName}:`, ranking);
  }
};

export function handleUserDisconnect(socket: Socket): void {
  const userInfo = roomUsers[socket.id];
  if (!userInfo) {
    console.log(`No user info found for socket ${socket.id}`);
    return;
  }

  const { roomName, userId, username } = userInfo;
  console.log(`User ${userId} - ${username} disconnected from room ${roomName}`);

  const room = rooms[roomName];
  if (room) {
    const participant = room.getParticipants().find((p) => p.userId === userId);
    if (participant) {
      participant.isConnected = false; // Marca como desconectado
    }

    delete roomUsers[socket.id];
    MessageChatActions.message(roomName, new Message('info', userId, username, "saiu"));

    // Verifica se todos os participantes conectados acertaram
    const connectedParticipants = room.getParticipants().filter((p) => p.isConnected);
    if (connectedParticipants.length > 0 && room.hasEveryoneAnsweredCorrectly()) {
      console.log(`All connected participants in room ${roomName} have answered correctly after ${username} disconnected.`);
      room.resetCorrectAnswers();
      TurnManager.startTurnTimer(roomName, 60); // Avança o turno
    }

    if (connectedParticipants.length === 0) {
      console.log(`Room ${roomName} is empty after disconnection. Deleting room.`);
      delete rooms[roomName];
      delete roomDrawings[roomName];
      RoomManager.emitRoomList();
    } else {
      RoomManager.emitParticipantsUpdate(roomName);
    }
  }
}

// Socket.IO Configuration
io.on('connection', (socket: Socket): void => {
  console.log(`Client connected: ${socket.id}`);
  socket.emit('room:all', { allRooms: Object.keys(rooms) });

  socket.on('room:create', (data: RoomDTO) => RoomManager.create(data));
  socket.on('room:join', (data: RoomUserDTO, callback: any) => RoomManager.join(socket, data, callback));
  socket.on('room:leave', (data: RoomUserDTO) => RoomManager.leave(socket, data));

  socket.on('drawing:stroke:start', (data: RoomDrawingStartStrokeDTO) => DrawingActions.strokeStart(data));
  socket.on('drawing:stroke:lastPoints', (data: RoomDrawingStrokeLastPointsDTO) => DrawingActions.strokeLastPoints(data));
  socket.on('drawing:clear', (data: RoomDTO) => DrawingActions.clear(data));
  socket.on('drawing:undo', (data: RoomDTO) => DrawingActions.undo(data));
  socket.on('drawing:redo', (data: RoomDTO) => DrawingActions.redo(data));

  socket.on('chat:answer:guess', (data: RoomUserAnswerDTO) => AnswerChatActions.guess(socket, data));

  socket.on('chat:message', ({ roomName, userId, username, text }: RoomUserMessageDTO) =>
    MessageChatActions.message(roomName, new Message(null, userId, username, text)));


  socket.on('game:turns:start', (data: RoomDTO) => GameManager.startTurns(socket, data));

  socket.on('disconnect', () => handleUserDisconnect(socket));
});

// Server startup
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
