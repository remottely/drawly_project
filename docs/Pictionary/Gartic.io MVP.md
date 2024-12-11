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
- [ ] polygon outside canvas limits

**TODO:**
- [x] (0.7.2): Stroke transparency
- [ ] Sound
- [ ] Share
	- [ ] Invite
	- [ ] Stream
- [ ] Info
- [ ] Close
- [ ] User can change background color dynamicaly
- [x] (0.8.0)When disconnect inside a game room, then when reconnect rejoin the same room and get all strokes registered in the server
- [x] (0.8.1)Improve all notifier var names
- [ ] redoDraw, get from server and not locally
- [ ] remover do servidor:
	- [ ] all messages, fazer como nos strokes, mandar q por vez
	- [ ] all answers, fazer como nos strokes, mandar q por vez