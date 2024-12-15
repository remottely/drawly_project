Criar um **MVP (Minimum Viable Product)** semelhante ao Gartic.io exige o desenvolvimento de várias funcionalidades essenciais para garantir uma experiência de jogo básica, mas funcional. Aqui está uma lista organizada por categorias:

---

### **1. Backend**

1. **Servidor de comunicação em tempo real**:
    - [x] Configurar um servidor com **Socket.IO** (Node.js ou outra tecnologia para WebSocket).
    - [x] Gerenciar eventos de conexão, desconexão e mensagens.
2. **Gerenciamento de salas**:
    - [x] Criar, listar e excluir salas.
    - [ ] Capacidade de definir salas públicas ou privadas.
    - [ ] Limitar o número de jogadores por sala.
3. **Sincronização do jogo**:
    - [ ] Lógica para alternar entre rodadas e turnos.
    - [ ] Escolher uma palavra para o jogador desenhista.
    - [x] Enviar atualizações em tempo real para os participantes (desenho, chat, etc.).
4. **Persistência de dados** (opcional para o MVP):
    - [ ] Armazenar dados de jogos em banco de dados (e.g., pontuação histórica, usuários).
5. **Gerenciamento de usuários**:
    - [ ] Sistema de autenticação (pode ser básico, como nomes únicos sem senha).
    - [x] Opção para jogar como visitante.

---

### **2. Frontend**

1. **Tela inicial**:
    - [ ] Login rápido (nome do jogador ou entrar como visitante).
    - [x] Botão para criar ou entrar em salas.
2. **Sistema de salas**:
    - [x] Lista de salas públicas disponíveis.
    - [ ] Campo para criar ou entrar em salas privadas (com código de sala).
3. **Tela de jogo**:
    - **Canvas de desenho**:
        - [ ] Ferramentas de desenho (pincel, borracha, balde, cores básicas).
    - **Chat em tempo real**:
        - [x] Enviar e exibir mensagens.
        - [ ] Ocultar mensagens do desenhista para evitar trapaças.
    - **Lista de jogadores**:
        - [ ] Exibir jogadores na sala com pontuação.
4. **Interface para rodadas e turnos**:
    - [ ] Exibir quem está desenhando.
    - [ ] Temporizador de rodada.
    - [ ] Atualizar dicas e respostas em tempo real.

---

### **3. Game Design e Lógica**

1. **Gerenciamento de palavras**:
    - [ ] Banco de palavras aleatórias (tema livre ou categorizado).
    - [ ] Regras para validar respostas dos jogadores.
2. **Pontuação**:
    - [ ] Sistema de pontuação baseado em:
        - Velocidade de acerto.
        - Desenhista receber pontos pelos acertos dos outros.
3. **Turnos e rodadas**:
    - [ ] Revezamento automático entre jogadores.
    - [ ] Definição de número de rodadas no início da sala.
4. **Dicas automáticas**:
    - [ ] Mostrar letras ou dicas progressivas ao longo do tempo.

---

### **4. Integração e Deploy**

1. **Web Application**:
    - [x] Desenvolver o frontend em **Flutter Web**, React ou outra tecnologia.
    - [ ] Garantir responsividade para mobile e desktop.
2. **Servidor**:
    - [ ] Hospedar o backend em serviços como **Heroku, AWS, Firebase Hosting** ou **Vercel**.
    - [ ] Configurar segurança básica (e.g., proteção contra flood no chat).
3. **Teste e Monitoramento**:
    - [ ] Implementar logs básicos para depuração de erros.
    - [ ] Testar simultaneidade com vários usuários.

---

### **5. Extras (após o MVP)**
- [ ] **Sistema de ranking global**.
- [ ] **Customização de avatares ou nomes**.
- [ ] Suporte a idiomas diferentes.
- [ ] Sistema anti-cheat (bloquear respostas copiadas no chat).
- [ ] Integração com redes sociais (login e compartilhamento).

---

### **Pilha sugerida**

- [x] **Frontend**: Flutter Web (você já domina) ou React.js.
- [x] **Backend**: Node.js com Socket.IO.
- [ ] l10n | i18n
- [ ] **Banco de Dados**: Firebase Firestore ou MongoDB.
- [ ] **Deploy**: Vercel para o frontend e Heroku/AWS para o backend.


**BUGS:**
- [ ] Polygon outside canvas limits.
- [ ] When entering room1, then leaving and entering room2, disconnecting, and performing some undos, the user is redirected back to room1.

**TODO:**
- [x] (0.7.2): Stroke transparency.
- [ ] Sound.
- [ ] Share.
	- [ ] Invite.
	- [ ] Stream.
- [ ] Info.
- [ ] Close.
- [ ] Allow the user to dynamically change the background color.
- [x] (0.8.0): When disconnected inside a game room, reconnect to the same room and retrieve all strokes registered on the server.
- [x] (0.8.1): Improve all notifier variable names.
- [x] (0.8.2): Organize files.
- [x] (0.9.0): Notify disconnection in the message chat.
- [x] (0.9.1): Organize backend `server.ts` (part 1).
- [x] (0.9.2): Organize backend `server.ts` (part 2).
- [x] (0.9.3): Organize backend `server.ts` (part 3).
- [x] (0.9.4): Organize backend `server.ts` (part 4).
- [x] (0.9.5): Organize backend `server.ts` (part 5).
- [x] (0.9.6): Organize backend `server.ts` (part 6).
- [x] (0.9.7): Rename `draw_board` package to `drawing_board`.
- [x] (0.10.0): Implement currentDrawer logic + timer.
- [x] (0.10.1): Bug: DrawingBoard undo and redo not working.
- [x] (0.11.0): Clear the board when changing the currentDrawer.
- [x] (0.11.1): Bug: Hot reload invoking multiple `_joinGameRoom()`.
- [x] (0.11.2): Bug: Simulating disconnection not working as expected (issue with `definedNumberOfPlayers`).
- [x] (0.12.0): Implement manual turn start functionality.
- [x] (0.13.0): Implement random game theme.
- [x] (0.14.0): Implement answer validation on the backend and emit the result to the frontend.
- [x] (0.15.0): Refactor `socket.io` event names.
- [x] (0.16.0): Display the answer in green in the chat when correct.
- [x] (0.17.0): Enhance code, remove unnecessary comments.
- [x] (0.18.0): fix CanvasSideBar dynamically height
- [ ] Server cleanup:
	- [ ] (0.?.0): Handle answers individually like strokes.
	- [ ] (0.?.0): Handle messages individually like strokes.
- [ ] (0.?.0): Validate the minimum number of players.
- [ ] (0.?.0): RedoDraw.
	- [ ] Retrieve from the server instead of locally.
	- [ ] Fix issue where some redos are lost when someone disconnects.
- [ ] (0.?.0): Add a rule to prevent users from typing words related to the answer (use AI client-side?).
- [ ] (0.?.0): Bug: Canvas border should not be dynamic.
- [ ] (0.?.0): Bug: `cmd+z` and `cmd+y` do not work on the web. This might be expected, but find a workaround.
- [ ] (0.?.0): Bug: `shiftLeft` and `shiftRight` do not work under any circumstances.
- [ ] (0.?.0): error treatment on frontend side