### **1. Backend**

1. **Real-time communication server**:
    - [x]  Set up a server using **Socket.IO** (Node.js or another WebSocket technology).
    - [x]  Manage connection, disconnection, and message events.
2. **Room management**:
    - [x]  Create, list, and delete rooms.
    - [ ]  (0.?.0) Ability to define public or private rooms.
    - [ ]  (0.?.0) Limit the fixed number of players per room.
    - [ ]  (0.?.0) Limit the dynamic number of players per room.
3. **Game synchronization**:
    - [x]  (0.12.0) Logic to alternate between turns.
    - [ ]  (0.?.0) Logic to alternate between rounds.
    - [x]  (0.13.0) Choose a word for the drawing player.
    - [x]  Send real-time updates to participants (drawing, chat, etc.).
4. **Data persistence** (optional for MVP):
    - [ ]  (0.?.0) Store game data in a database (e.g., historical scores, users).
5. **User management**:
    - [ ]  (0.?.0) Authentication system (can be basic, like unique names without a password).
    - [x]  Option to play as a guest.

---

### **2. Frontend**

1. **Home screen**:
    - [ ]  (0.?.0) Quick login (player name or enter as a guest).
    - [x]  Button to create or join rooms.
2. **Room system**:
    - [x]  List of available public rooms.
    - [x]  Field to create or join public rooms.
    - [ ]  (0.?.0) Field to create or join private rooms (with room code).
3. **Game screen**:
    - **Drawing canvas**:
        - [x]  Drawing tools (brush, eraser, basic colors).
        - [ ]  (0.?.0) Drawing tools (bucket fill).
    - **Real-time chat**:
        - [x]  Send and display messages.
        - [x]  (0.14.0) Hide messages from the drawer to prevent cheating.
    - **Player list**:
        - [ ]  (0.?.0) Display players in the room with scores.
4. **Rounds and turns interface**:
    - [x]  (0.13.0) Show who is drawing.
    - [x]  (0.10.0) Round timer.
    - [ ]  (0.?.0) Update hints and answers in real-time.

---

### **3. Game Design and Logic**

1. **Word management**:
    - [ ]  (0.?.0) Randomized word bank (free or categorized themes).
    - [ ]  (0.?.0) Rules for validating player answers.
2. **Scoring system**:
    - [ ]  Point system based on:
        - (0.?.0) Speed of correct guesses.
        - (0.?.0) Drawer receives points for others' correct guesses.
3. **Turns and rounds**:
    - [ ]  (0.?.0) Automatic player rotation.
    - [ ]  (0.?.0) Define the number of rounds at the room's start.
4. **Automatic hints**:
    - [ ]  (0.?.0) Show letters or progressive hints over time.

---

### **4. Integration and Deployment**

1. **Web Application**:
    - [x]  Develop the frontend in **Flutter Web**, React, or another technology.
    - [ ]  (0.?.0) Ensure responsiveness for mobile and desktop.
2. **Server**:
    - [ ]  (0.?.0) Host the backend on services like **Heroku, AWS, Firebase Hosting**, or **Vercel**.
    - [ ]  (0.?.0) Configure basic security (e.g., flood protection in chat).
3. **Testing and Monitoring**:
    - [ ]  (0.?.0) Implement basic logs for error debugging.
    - [ ]  (0.?.0) Test concurrency with multiple users.

---

### **5. Extras (post-MVP)**

- [ ]  (0.?.0) **Global ranking system**.
- [ ]  (0.?.0) **Customization for avatars or names**.
- [ ]  (0.?.0) Multi-language support.
- [ ]  (0.?.0) Anti-cheat system (block copied answers in chat).
- [ ]  (0.?.0) Social media integration (login and sharing).

---

### **Suggested Stack**

- [x]  **Frontend**: Flutter Web (you already excel here) or React.js.
- [x]  **Backend**: Node.js with Socket.IO.
- [ ]  (0.?.0) l10n | i18n
- [ ]  (0.?.0) **Database**: Firebase Firestore or MongoDB.
- [ ]  (0.?.0) **Deploy**: Vercel for frontend and Heroku/AWS for backend.

---

**BUGS:**
- [ ] (0.?.0) Polygon outside canvas limits.
- [ ] When entering room1, then leaving and entering room2, disconnecting, and performing some undos, the user is redirected back to room1.

---

### **TODO:**

- [x]  (0.7.2): Stroke transparency.
- [ ] DETECTAR QUANDO O CLIENTE SAIR DO SITE OU DO APP, PARA QUE TODOS OS LISTENERS DO SOCKET.IO SEJAM FECHADOS DA MANEIRA CORRETA.
- [ ] MIGRAR TODOS OS EVENTOS PARA ENUMS Q SE TRANSFORMAM EM STRINGS??
- [ ]  (0.?.0): Sounds.
- Share:
    - [ ]  (0.?.0): Invite.
    - [ ]  (0.?.0): Stream.
- [ ]  (0.?.0): Info.
- [ ]  (0.?.0): Close.
- [ ]  (0.?.0): Allow the user to dynamically change the background color.
- [x]  (0.8.0): Reconnect to the same room after disconnection and retrieve all strokes from the server.
- [x]  (0.8.1): Improve all notifier variable names.
- [x]  (0.8.2): Organize files.
- [x]  (0.9.0): Notify disconnection in the message chat.
- [x]  (0.9.1): Organize backend `server.ts` (part 1).
- [x]  (0.9.2): Organize backend `server.ts` (part 2).
- [x]  (0.9.3): Organize backend `server.ts` (part 3).
- [x]  (0.9.4): Organize backend `server.ts` (part 4).
- [x]  (0.9.5): Organize backend `server.ts` (part 5).
- [x]  (0.9.6): Organize backend `server.ts` (part 6).
- [x]  (0.9.7): Rename `draw_board` package to `drawing_board`.
- [x]  (0.10.0): Implement currentDrawer logic + timer.
- [x]  (0.10.1): Bug: DrawingBoard undo and redo not working.
- [x]  (0.11.0): Clear the board when changing the currentDrawer.
- [x]  (0.11.1): Bug: Hot reload invoking multiple `_joinGameRoom()`.
- [x]  (0.11.2): Bug: Simulating disconnection not working as expected (issue with `definedNumberOfPlayers`).
- [x]  (0.12.0): Implement manual turn start functionality.
- [x]  (0.13.0): Implement random game theme.
- [x]  (0.14.0): Validate answers on the backend and emit the result to the frontend.
- [x]  (0.15.0): Refactor `socket.io` event names.
- [x]  (0.16.0): Display correct answers in green in the chat.
- [x]  (0.17.0): Enhance code, remove unnecessary comments.
- [x]  (0.18.0): Fix CanvasSideBar dynamic height.
- [x]  (0.18.1): Fix message chat.
- [x]  (0.18.2): Enhance code.
- [x]  (0.19.0): Add message icon.
- [x]  (0.19.1): Migrate all backend to OOP.
- [x]  (0.20.0): Add answer icon.
- [x]  (0.21.0): Add keyboard enter to send messages and answers in chat.
- [x]  (0.22.0): Add all socket DTOs.
- [x]  (0.22.1): Enhance the UI
-  (0.23.0):
	- [x] Clean the answers chat each turn.
	- [x] Message and answer chats should keep the scroll always showing the latest message and add padding to indicate that new messages will appear.
- [x]  (0.?.0): Bold "username" in the chat.
- [x] (0.23.1): enhance 
- [x] (0.24.0): Change the architecture of the way SocketManager manipulates the events, now events are globally registrered only one time and replicate the callbacks across the app using a smart way to call the callbacks.
- [x] (0.24.1): Bug: Reset all canvas states when the event `turn:new` is triggered.
- [ ]  (0.?.0): Detect inactivity, warn the user, and kick after one minute.
- [ ]  (0.?.0): Timeout... The answer was: "answer". Next turn for "username".
- [ ]  (0.?.0): Block chat messages "containing any part of the answer."
- [ ]  (0.?.0): End game when there are no players in the answer chat.
- [ ]  (0.?.0): Wait 15 seconds to switch rooms.
- [ ]  (0.?.0): Create new themes.
- [ ]  (0.?.0): Favorited rooms.
- [ ]  (0.?.0): Chat functionality.
- [ ]  (0.?.0): Validate the minimum number of players.
- (0.?.0): RedoDraw:
    - [ ]  Retrieve strokes from the server instead of locally.
    - [ ]  Fix issues where some redos are lost when someone disconnects.
- [ ]  (0.?.0): Add a rule to prevent users from typing words related to the answer (use AI client-side?).
- [ ]  (0.?.0): Bug: Canvas border should not be dynamic.
- [ ]  (0.?.0): Bug: `cmd+z` and `cmd+y` do not work on the web. Find a workaround if expected behavior.
- [ ]  (0.?.0): Bug: `shiftLeft` and `shiftRight` do not work.
- [ ]  (0.?.0): Add error handling on the frontend.
- [ ]  (0.?.0): Allow users to create their own games.
- [ ]  (0.?.0): Close answers based on the word.
- [ ]  (0.?.0): Add user avatars.
- [ ]  (0.?.0): Add Firebase Authentication (anonymous).
- [ ]  (0.?.0): Add Firebase Authentication (email/password).
- [ ]  (0.?.0): Add Firebase Authentication (Google).
- [ ]  (0.?.0): Implement bucket system.
- [ ]  (1.?.0): Add draw report functionality.
- **Answer chat dynamic hint text**:
    - "Answer here..."
    - "Timeout..."
    - "Waiting for the drawing."
- **Answer chat suffix tab button**:
    - Show tab info "Press 'tab' to activate the text."
- **Message chat dynamic hint text**:
    - "You must log in to chat."
- **Rules alert**:
    - [ ]  Theme.
    - [ ]  Goal.
    - [ ]  Language.
    - [ ]  Animation for the rules.
    - [ ]  "Do not draw letters, numbers, or symbols, okay?"
    - [ ]  Confirm.
- [ ]  Add user profile picture.
- [ ]  Dialog to confirm leaving the room.
- **Reports**
    - [ ]  Report a drawing
    - [ ]  General report functionality
- **Accumulate in the database**:
    - [ ]  Store all points earned from games completed by the user. These points can be used within the Remottely ecosystem.
- [ ]  Limit the number of messages each user can send per second or minute.
- [ ]  Bug: When drawing near the end of the turn timer, strokes are carried over to the next turn.
- [ ] 