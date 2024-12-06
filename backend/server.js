require("dotenv").config();
const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");
const { createRoom, getRoomParticipants } = require("./src/rooms/roomManager");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Allow connections from any source (change for production)
  },
});

const PORT = process.env.PORT || 5555;

app.use(cors());
app.use(express.json());

// Map to store drawing history for each room
const roomDrawings = {};
const backupRoomDrawings = {};

// Set to manage the list of available rooms
const availableRooms = new Set();

io.on("connection", (socket) => {
  console.log(`Client connected: ${socket.id}`);

  // Send the list of available rooms to the newly connected client
  socket.emit("roomList", Array.from(availableRooms));

  // Event to create a new room
  socket.on("createRoom", (roomName) => {
    if (!availableRooms.has(roomName)) {
      availableRooms.add(roomName);
      console.log(`Room created: ${roomName}`);
      io.emit("roomList", Array.from(availableRooms)); // Broadcast updated room list to all clients
    }
  });

  // Event when a user joins a room
  socket.on("joinRoom", ({ username, room }) => {
    if (!availableRooms.has(room)) {
      console.log(`Room ${room} does not exist`);
      return;
    }

    socket.join(room);
    createRoom(room, username);

    // Send the accumulated drawing to the client who just joined
    if (roomDrawings[room]) {
      console.log(
        `Sending full drawing to client ${socket.id} for room ${room}`
      );
      socket.emit("draw", { strokes: roomDrawings[room] });
    } else {
      console.log(`No drawing available for room ${room}`);
    }

    const participants = getRoomParticipants(room);
    io.to(room).emit("updateParticipants", participants);

    console.log(`${username} joined room ${room}`);
    io.to(room).emit("newMessage", {
      username: "System",
      message: `${username} joined the room.`,
    });
  });

  // // Event to send the current room list to a client
  // socket.on("getRoomList", () => {
  //   socket.emit("roomList", Array.from(availableRooms));
  // });

  // Event for leaving a room
  socket.on("leaveRoom", ({ username, room }) => {
    console.log(`${username} left room ${room}`);

    // Remove user from the room participants
    socket.leave(room);

    // Notify other users in the room
    io.to(room).emit("newMessage", {
      username: "System",
      message: `${username} left the room.`,
    });

    // Optionally, you could update room participant lists here
    const participants = getRoomParticipants(room);
    io.to(room).emit("updateParticipants", participants);
  });

  // Event to handle sending messages
  socket.on("sendMessage", ({ username, room, message }) => {
    io.to(room).emit("newMessage", { username, message });
  });

  // Event to handle drawing data
  socket.on("draw", ({ room, strokes }) => {
    console.log(`Drawing received for room ${room}:`, strokes);

    // If the room doesn't have a drawing history, create an empty array
    if (!roomDrawings[room]) {
      roomDrawings[room] = [];
    }

    if (!backupRoomDrawings[room]) {
      backupRoomDrawings[room] = [];
    }

    // Append new strokes to the room's drawing history
    roomDrawings[room].push(...strokes);

    // Broadcast the new strokes to all clients in the room
    io.to(room).emit("draw", { strokes: strokes });

    console.log(`Drawing broadcasted to room ${room}:`, strokes);
  });

  socket.on("clearDraw", ({ room }) => {
    console.log(`Clear draw received for room ${room}`);

    roomDrawings[room] = [];
    backupRoomDrawings[room] = [];

    // Broadcast the new strokes to all clients in the room
    io.to(room).emit("clearDraw");

    console.log(`Clear draw broadcasted to room ${room}`);
  });

  socket.on("undoDraw", ({ room }) => {
    console.log(`Undo draw received for room ${room}`);

    let poppedValue = roomDrawings[room].pop();
    backupRoomDrawings[room].push(poppedValue);

    // Broadcast the new strokes to all clients in the room
    io.to(room).emit("undoDraw");

    console.log(`Undo draw broadcasted to room ${room}`);
  });

  socket.on("redoDraw", ({ room }) => {
    console.log(`Redo draw received for room ${room}`);

    let poppedValue = backupRoomDrawings[room].pop();
    roomDrawings[room].push(poppedValue);

    // Broadcast the new strokes to all clients in the room
    io.to(room).emit("redoDraw");

    console.log(`Redo draw broadcasted to room ${room}`);
  });
  // Event for handling disconnection
  socket.on("disconnect", () => {
    console.log(`Client disconnected: ${socket.id}`);
  });
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
