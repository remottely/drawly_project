### **Suggested Stack**

- **Frontend**: Flutter Web (you already excel here) or React.js.
- **Backend**: Node.js with Socket.IO.
- **Database**: Firebase Firestore or MongoDB.
- **Deploy**: Vercel for frontend and Heroku/AWS for backend.
- Host the backend on services like Heroku, AWS, Firebase Hosting, or Vercel.

---

### **V1**

- [x] (0.7.2) Stroke transparency.
- [x] (0.8.0) Reconnect to the same room after disconnection and retrieve all strokes from the server.
- [x] (0.8.1) Improve all notifier variable names.
- [x] (0.8.2) Organize files.
- [x] (0.9.0) Notify disconnection in the message chat.
- [x] (0.9.1) Organize backend `server.ts` (part 1).
- [x] (0.9.2) Organize backend `server.ts` (part 2).
- [x] (0.9.3) Organize backend `server.ts` (part 3).
- [x] (0.9.4) Organize backend `server.ts` (part 4).
- [x] (0.9.5) Organize backend `server.ts` (part 5).
- [x] (0.9.6) Organize backend `server.ts` (part 6).
- [x] (0.9.7) Rename `draw_board` package to `drawing_board`.
- [x] (0.10.0) Implement currentDrawerUserId logic + timer.
- [x] (0.10.1) Bug: DrawingBoard undo and redo not working.
- [x] (0.11.0) Clear the board when changing the currentDrawerUserId.
- [x] (0.11.1) Bug: Hot reload invoking multiple `_joinGameRoom()`.
- [x] (0.11.2) Bug: Simulating disconnection not working as expected (issue with `definedNumberOfPlayers`).
- [x] (0.12.0) Implement manual turn start functionality.
- [x] (0.13.0) Implement random game theme.
- [x] (0.14.0) Validate answers on the backend and emit the result to the frontend.
- [x] (0.15.0) Refactor `socket.io` event names.
- [x] (0.16.0) Display correct answers in green in the chat.
- [x] (0.17.0) Enhance code, remove unnecessary comments.
- [x] (0.18.0) Fix CanvasSideBar dynamic height.
- [x] (0.18.1) Fix message chat.
- [x] (0.18.2) Enhance code.
- [x] (0.19.0) Add message icon.
- [x] (0.19.1) Migrate all backend to OOP.
- [x] (0.20.0) Add answer icon.
- [x] (0.21.0) Add keyboard enter to send messages and answers in chat.
- [x] (0.22.0) Add all socket DTOs.
- [x] (0.22.1) Enhance the UI.
- [x] (0.23.0) Clean the answers chat each turn. Message and answer chats should keep the scroll always showing the latest message and add padding to indicate that new messages will appear.
- [x] (0.?.0) Bold "username" in the chat.
- [x] (0.23.1) enhance the code.
- [x] (0.24.0) Change the architecture of the way SocketManager manipulates the events, now events are globally registrered only one time and replicate the callbacks across the app using a smart way to call the callbacks.
- [x] (0.24.1) Bug: Reset all canvas states when the event `turn:new` is triggered.
- [x] (0.24.2) add very_good_analysis to the project.
- [x] (0.24.3) bug: fix all onEvents callback formats.
- [x] Manage connection, disconnection, and message events.
- [x] Create room.
- [x] List rooms.
- [x] (0.12.0) Logic to alternate turns.
- [x] (0.13.0) Choose a word for the drawing player.
- [x] Send real-time updates to participants (drawing, chat, etc.).
- [x] Option to play as a guest.
- [x] Quick login (player name or enter as a guest).
- [x] Button to create or join rooms.
- [x] List of available public rooms.
- [x] Field to create or join public rooms.
- [x] Drawing tools (brush, eraser, basic colors).
- [x] Send and display messages.
- [x] (0.14.0) Hide messages from the drawer to prevent cheating.
- [x] (0.13.0) Show who is drawing.
- [x] (0.10.0) Round timer.
- [x] (0.?.0) Update hints and answers in real-time.
- [x] (0.?.0) Validate the minimum number of players to 2 before starts the game.
- [x] (0.25.0) Put all texts in Portuguese.
- [x] (0.26.0) Improve the design of the participants section.
- [x] (0.27.0) Implement functionality to select, save and retrieve an avatar in local storage.
- [x] (0.28.0) Retrieve and display all the participants avatar in the game room.
- [x] (0.29.0) Enhance design system of all app.
- [x] (0.30.0) Improve participant handling in the Room class.
- [x] (0.30.1) Fix all problems made by Participants migration.
- [x] (0.31.0) Change backend to manipulate only userIds and not usernames.
- [x] (0.31.1) drawly tab problems: fix all alerts
- [x] (0.31.2) drawly packages tab problems: fix all alerts (part 1)
- [x] (0.31.3) drawly packages tab problems: fix all alerts (part 2)
- [x] (0.32.0) Add new username logic to backend and frontend
- [x] (0.32.1) drawly tab problems: fix all alerts
- [x] (0.33.2) Bug with strokes drawing:stroke not working properly
- [x] (0.33.3) Add userId logic into the frontend side (part 1)
- [x] (0.33.4) Add userId logic into the frontend side (part 2)
- [x] (0.34.1) Organizing code
- [x] (0.35.0) Buffer strokes every 50ms.
- [x] (0.36.0) **Participant Counter**: Detect the number of participants in the room and emit turn completion when:
  - A participant leaves the room **and** the increment of players who guessed correctly matches the expected count.
  - Each time someone guesses correctly, increment the counter **and** check if the correct guesses for the turn reach the expected count.
- [x] (0.36.1) **Bug**: Ensure logic continues to function when a participant disconnects.
- [x] (0.37.0) Add scoring system based on guess time.
- [x] (0.37.1) Apply various UI improvements.
- [x] (0.38.0) Initialize Golang migration with a simple example.
- [x] (0.38.1) Add CORS and other configurations in the new Golang backend (part 1).
- [x] (0.38.2) Migrate almost all functionality from Node.js to Golang backend (part 2).
- [x] (0.38.3) Complete the migration of remaining Node.js features to Golang backend (part 3).
- [x] (0.39.0) Add the first Golang unit test (`room:leave`).
- [x] (0.40.0) **Bug**: Fix incorrect Flutter timer feedback when a turn changes before the previous turn finishes.
- [x] (0.40.1) **Bug**: Correct the logic for calculating the user's current score.
- [x] (0.41.0) **Feature**: Emit `room:participants:update` as a list, ordered by each participant's score in descending order.
- [x] (0.42.0) Implement tiebreaker logic on the Golang side based on the previous round.
- [x] (0.43.0) Highlight the local user and the drawer in the UI.
- [x] (0.44.0) improve some ui colors
- [x] (0.44.1) Bug: undo and redo not working
- [x] (0.44.2) Bug: room:join not calling drawing:stroke:all
- [x] (0.44.3) Bug: when enter in a room already started the game, button start game are activated
- [x] (0.45.0) feature: implementar isGameStarted para ser controlado do lado do backend
- [ ] (0.46.0) Ao perder conexao, verificar se a rodada deve ser finalizada
- [ ] (0.46.1) bug: ao perder conexao a rodada nao finaliza
- [ ] Bug: mensagem de "... saiu" nunca sendo emitida
- [ ] Bug: alternancia entre respostas de forma infinita na mesma rodada
- [ ] Ao sair da sala, verificar se a rodada deve ser finalizada
- [ ] Bug: quando desconectado anteriormente em node ele continuava na mesma pagina, agora ele navega para uma pagina anterior(pop), corrigir isso
- [ ] Bug: ao entrar na pagina de listas de salas nao aparece nenhuma sala ate eu criar uma nova sala
- [ ] feature: implementar Room como um objeto do tipo json nativamente??
- [ ] feature: ao entrar uma pessoa nova na sala, ela nao pode chutar, mas tb a rodada nao termina pois espera q a mesma quantidade de pessoas junto com a q acabou de entrar acertem a palavra. permitir q a nova pessoa tb adivinhe e acerte a palavra? sim.
- [ ] Add nested navigation.
- [ ] **Bug**: Ensure geometric shapes are clipped when exceeding the drawing board boundaries.
- [ ] **Disconnection**: Prevent sending cached data upon disconnection by removing this default Socket.IO behavior.
- [ ] Change the way the server sends room data.
- [ ] Add validation to only display rooms that are not full.
- [ ] Create a new form to allow users to better personalize room configurations.
- [ ] Add a feature to report the drawer.
- [ ] Add a feature to report a player. (Add a feature to report a message?)

### Validações e Regras de Negócio

- [ ] (0.?.0) Minimum and maximum length validation for usernames (frontend and backend).
- [x] (0.33.0) Limit the fixed number of players per room to 12. Part 1 (backend).
- [x] Limit the fixed number of players per room to 12. Part 2 (frontend).
  - [x] (0.33.1) Add ErrorDTO and pop action. Add room:join with future callback.
- [ ] (0.?.0) Block server to open more than one connection with same userId (backend).
- [ ] (0.?.0) Define the number of rounds at the room's based on total points. When a player has more or equal to max points, the game ends.

---

### Refatoração e Organização de Código

- [ ] Refactoring: Separate each `onEvent` handler into its own file for better modularization, organization and maintainability.
- [ ] (0.?.0) Improve the way backend open and close Socket.IO connections.

---

### Bugs e Correções

- [x] (0.34.0) Bug: when a player enters a room with a game already started, "start game" appears on the screen Remove it and introduce the new player.
- [ ] (0.?.0) Bug: When entering room1, then leaving and entering room2, disconnecting, and performing some undos, the user is redirected back to room1.
- [ ] (0.?.0) Bug with "List all rooms" when going back and entering again in the `DrawGameRoomSelectionPage`.
- [ ] (0.?.0) Bug: `cmd+z` and `cmd+y` do not work on the web. Find a workaround if expected behavior.
- [ ] (0.?.0) Bug: `shiftLeft` and `shiftRight` do not work.

---

### Funcionalidades Essenciais

- [ ] (0.?.0) unique avatars.
- [ ] (0.?.0) Add timer.
- [ ] (0.?.0) Logic between turns.
- [ ] (0.?.0) Randomized word bank categorized themes.
- [ ] (0.?.0) Drawing tools (bucket fill).
- [ ] (0.?.0) Display players in the room with scores.
- [ ] (0.?.0) Point system based on speed of correct guesses.
- [ ] (0.?.0) Point system where the drawer receives points for others' correct guesses.
- [ ] (0.?.0) Show letters or progressive hints over time.
- [ ] (0.?.0) Detect inactivity, warn the user, and kick after one minute.
- [ ] (0.?.0) End game when there are no players in the answer chat.

---

### Segurança e Logs

- [ ] (0.?.0) Configure basic security (e.g., flood protection in chat).
- [ ] (0.?.0) Implement basic logs for error debugging.

---

### Responsividade e Experiência do Usuário

- [ ] (0.?.0) Ensure responsiveness for mobile and desktop.
- [ ] (0.?.0) Sounds.
- [ ] (0.?.0) Close(return).
- [ ] (0.?.0) Add Firebase Authentication (anonymous).
- **Answer chat dynamic hint text**:
  - "Answer here..."
  - "Timeout..."
  - "Waiting for the drawing."

---

### Testes e Conectividade

- [ ] (0.?.0) Test concurrency with multiple users.
- [ ] (0.?.0) Detect when the client leaves the website or app to ensure all **Socket.IO** listeners are properly closed.

---

### **V2**

- [ ] (0.?.0) Change current drawer from app bar to participants list feedback.
- [ ] (0.?.0) Wait 15 seconds to switch rooms.
- [ ] (0.?.0) Migrate all events to enums that automatically convert to strings.
- (1.?.0) RedoDraw:
  - [ ] Retrieve strokes from the server instead of locally.
  - [ ] Fix issues where some redos are lost when someone disconnects.
- [ ] (1.?.0) Ability to define public or private rooms.
- [ ] (1.?.0) Limit the number of players per room dynamically.
- [ ] (1.?.0) Store game data in a database (e.g., historical scores, users).
- [ ] (1.?.0) Field to create or join private rooms (with room code).
- [ ] (1.?.0) l10n | i18n.
- Share:
  - [ ] (0.?.0): Invite.
  - [ ] (0.?.0) Stream.
- [ ] (0.?.0) Info.
- [ ] (0.?.0) Timeout... The answer was: "answer". Next turn for "username".
- [ ] (0.?.0) Block chat messages "containing any part of the answer."
- [ ] (0.?.0) Add error handling on the frontend.
- [ ] (0.?.0) Add Firebase Authentication (email/password).
- **Answer chat suffix tab button**:
  - Show tab info "Press 'tab' to activate the text."
- **Message chat dynamic hint text**:
  - "You must log in to chat."
- **Rules alert**:
  - [ ] Theme.
  - [ ] Goal.
  - [ ] Language.
  - [ ] Animation for the rules.
  - [ ] "Do not draw letters, numbers, or symbols, okay?"
  - [ ] Confirm.
- [ ] Limit the number of messages each user can send per second or minute.
- [ ] (0.?.0) Polygon outside canvas limits.

---

### **V3**

- [ ] (2.?.0) **Global ranking system**.
- [ ] (2.?.0) **Customization for avatars or names**.
- [ ] (2.?.0) Multi-language support.
- [ ] (2.?.0) Anti-cheat system (block copied answers in chat).
- [ ] (0.?.0) Social media integration (login and sharing).
- [ ] (0.?.0) Allow the user to dynamically change the background color.
- [ ] (0.?.0) Add a rule to prevent users from typing words related to the answer (use AI client-side?).
- [ ] (0.?.0) Create new themes.
- [ ] (0.?.0) Favorited rooms.
- [ ] (0.?.0) Bug: Canvas border should not be dynamic.
- [ ] (0.?.0) Allow users to create their own games.
- [ ] (0.?.0) Close answers based on the word.
- [ ] (0.?.0) Add user avatars.
- [ ] (0.?.0) Add Firebase Authentication (Google).
- [ ] Add user profile picture.
- [ ] Dialog to confirm leaving the room.
- [ ] Report a drawing.
- [ ] General report functionality.
- [ ] Store all points earned from games completed by the user. These points can be used within the Remottely ecosystem.
- [ ] Bug: When drawing near the end of the turn timer, strokes are carried over to the next turn.
- [ ] Daily challenges.
- [ ] **Feature**: Add difficulty levels such as Easy, Medium, Hard, and Expert to enhance gameplay customization.

---

Regrad de negocio:

- se o player for premium ele tem ajude de ia?
