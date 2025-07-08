const test = require('node:test');
const assert = require('node:assert');
const {
  RoomManager,
  AnswerChatActions,
  TurnManager,
  rooms,
  roomDrawings,
  roomUsers,
  io
} = require('../dist/server.js');

// Helper to reset internal state between tests
function resetState() {
  for (const key of Object.keys(rooms)) delete rooms[key];
  for (const key of Object.keys(roomDrawings)) delete roomDrawings[key];
  for (const key of Object.keys(roomUsers)) delete roomUsers[key];
}

test('guess emits error when room does not exist', () => {
  resetState();
  const fakeSocket = { emitted: null, emit(event, data) { this.emitted = { event, data }; } };

  AnswerChatActions.guess(fakeSocket, { roomName: 'missing', userId: 'u1', username: 'U1', text: 'word' });

  assert.strictEqual(fakeSocket.emitted.event, 'error');
  assert.strictEqual(fakeSocket.emitted.data.message.includes('does not exist'), true);
});

test('guess emits error when no current word is set', () => {
  resetState();
  const roomName = 'room1';
  RoomManager.create({ roomName });
  const fakeSocket = { id: 's1', join() {}, emitted: null, emit(event, data) { this.emitted = { event, data }; } };
  RoomManager.join(fakeSocket, { roomName, userId: 'u1', username: 'U1', userAvatar: null, isLogged: true }, () => {});

  AnswerChatActions.guess(fakeSocket, { roomName, userId: 'u1', username: 'U1', text: 'test' });

  assert.strictEqual(fakeSocket.emitted.event, 'error');
  assert.strictEqual(fakeSocket.emitted.data.message.includes('No word'), true);
});

test('correct guess awards points and notifies', () => {
  resetState();
  const roomName = 'room2';
  RoomManager.create({ roomName });

  const socket1 = { id: 's1', join() {}, emit() {} };
  const socket2 = { id: 's2', join() {}, emit() {} };
  const socket3 = { id: 's3', join() {}, emit() {} };
  RoomManager.join(socket1, { roomName, userId: 'drawer', username: 'Drawer', userAvatar: null, isLogged: true }, () => {});
  RoomManager.join(socket2, { roomName, userId: 'guesser1', username: 'Guesser1', userAvatar: null, isLogged: true }, () => {});
  RoomManager.join(socket3, { roomName, userId: 'guesser2', username: 'Guesser2', userAvatar: null, isLogged: true }, () => {});

  const room = rooms[roomName];
  room.currentWord = 'hello';

  const originalTo = io.to;
  const events = [];
  io.to = () => ({ emit(event, data) { events.push({ event, data }); } });

  AnswerChatActions.guess(socket2, { roomName, userId: 'guesser1', username: 'Guesser1', text: 'hello' });

  const participant = room.getParticipants().find(p => p.userId === 'guesser1');
  const drawer = room.getParticipants().find(p => p.userId === 'drawer');

  assert.strictEqual(participant.score > 0, true);
  assert.strictEqual(drawer.score, 20);
  const resultEvent = events.find(e => e.event === 'chat:answer:result');
  assert.ok(resultEvent, 'expected chat:answer:result to be emitted');
  assert.strictEqual(resultEvent.data.isCorrect, true);

  io.to = originalTo;
});

test('advances turn when everyone answered correctly', () => {
  resetState();
  const roomName = 'room3';
  RoomManager.create({ roomName });

  const socket1 = { id: 's1', join() {}, emit() {} };
  const socket2 = { id: 's2', join() {}, emit() {} };
  RoomManager.join(socket1, { roomName, userId: 'drawer', username: 'Drawer', userAvatar: null, isLogged: true }, () => {});
  RoomManager.join(socket2, { roomName, userId: 'guess', username: 'Guess', userAvatar: null, isLogged: true }, () => {});

  const room = rooms[roomName];
  room.currentWord = 'word';

  let timerCalled = false;
  const originalTimer = TurnManager.startTurnTimer;
  TurnManager.startTurnTimer = () => { timerCalled = true; };

  AnswerChatActions.guess(socket2, { roomName, userId: 'guess', username: 'Guess', text: 'word' });

  assert.strictEqual(timerCalled, true);

  TurnManager.startTurnTimer = originalTimer;
});
