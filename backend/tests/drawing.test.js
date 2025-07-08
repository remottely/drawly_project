const test = require('node:test');
const assert = require('node:assert');
const {
  Drawing,
  Stroke,
  Offset,
  Room,
  Participant,
} = require('../dist/server.js');

function createStroke() {
  return new Stroke([new Offset(0, 0)], 0xff0000, 5, 1, 'normal', false);
}

test('addStroke appends a stroke', () => {
  const drawing = new Drawing();
  const stroke = createStroke();
  drawing.addStroke(stroke);
  assert.strictEqual(drawing.getStrokes().length, 1);
  assert.strictEqual(drawing.getStrokes()[0], stroke);
});

test('addStrokeLastPoints appends points to last stroke', () => {
  const drawing = new Drawing();
  const stroke = createStroke();
  drawing.addStroke(stroke);
  drawing.addStrokeLastPoints([new Offset(1, 1), new Offset(2, 2)]);
  assert.strictEqual(drawing.getStrokes()[0].points.length, 3);
});

test('clear removes strokes and backups', () => {
  const drawing = new Drawing();
  drawing.addStroke(createStroke());
  drawing.undo();
  drawing.clear();
  assert.strictEqual(drawing.getStrokes().length, 0);
  assert.strictEqual(drawing.backupStrokes.length, 0);
});

test('undo moves stroke to backup', () => {
  const drawing = new Drawing();
  const stroke = createStroke();
  drawing.addStroke(stroke);
  const undone = drawing.undo();
  assert.strictEqual(undone, stroke);
  assert.strictEqual(drawing.getStrokes().length, 0);
  assert.strictEqual(drawing.backupStrokes.length, 1);
});

test('redo restores stroke from backup', () => {
  const drawing = new Drawing();
  const stroke = createStroke();
  drawing.addStroke(stroke);
  drawing.undo();
  const redone = drawing.redo();
  assert.strictEqual(redone, stroke);
  assert.strictEqual(drawing.getStrokes().length, 1);
  assert.strictEqual(drawing.backupStrokes.length, 0);
});

test('room advanceTurn cycles through participants', () => {
  const room = new Room('room');
  room.addParticipant(new Participant('1', 'A', null, true));
  room.addParticipant(new Participant('2', 'B', null, true));
  room.addParticipant(new Participant('3', 'C', null, true));
  assert.strictEqual(room.getCurrentDrawer().userId, '1');
  room.advanceTurn();
  assert.strictEqual(room.getCurrentDrawer().userId, '2');
  room.advanceTurn();
  assert.strictEqual(room.getCurrentDrawer().userId, '3');
  room.advanceTurn();
  assert.strictEqual(room.getCurrentDrawer().userId, '1');
});

test('room hasEveryoneAnsweredCorrectly returns expected value', () => {
  const room = new Room('room');
  const p1 = new Participant('1', 'A', null, true);
  const p2 = new Participant('2', 'B', null, true);
  room.addParticipant(p1);
  room.addParticipant(p2);
  room.participantCorrectAnswer('2');
  assert.strictEqual(room.hasEveryoneAnsweredCorrectly(), true);
  room.addParticipant(new Participant('3', 'C', null, true));
  assert.strictEqual(room.hasEveryoneAnsweredCorrectly(), false);
});
