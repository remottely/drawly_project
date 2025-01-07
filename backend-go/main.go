package main

import (
	"net/http"
	"os"
	"os/signal"
	"sort"
	"syscall"
	"time"

	"github.com/zishang520/engine.io/v2/log"
	"github.com/zishang520/engine.io/v2/types"
	"github.com/zishang520/socket.io/v2/socket"
)

func main() {
	log.DEBUG = true
	c := socket.DefaultServerOptions()
	c.SetServeClient(true)
	c.SetConnectionStateRecovery(&socket.ConnectionStateRecovery{})
	// c.SetAllowEIO3(true)
	c.SetPingInterval(300 * time.Millisecond)
	c.SetPingTimeout(200 * time.Millisecond)
	c.SetMaxHttpBufferSize(1000000)
	c.SetConnectTimeout(1000 * time.Millisecond)
	c.SetCors(&types.Cors{
		Origin:      "http://localhost:8081 http://localhost:8082 http://localhost:8083 http://localhost:8084 http://localhost:8085 http://localhost:8086 http://localhost:8087 http://localhost:8088",
		Credentials: true,
		Headers:     []string{"Content-Type", "Authorization"},
	})
	io := socket.NewServer(nil, nil)
	http.Handle("/socket.io/", io.ServeHandler(nil))
	go http.ListenAndServe(":5555", nil)

	io.On("connection", func(clients ...any) {
		client := clients[0].(*socket.Socket)

		// Evento: Criar Sala
		client.On("room:create", func(args ...interface{}) {
			// Verifica se o argumento é um mapa
			if len(args) > 0 {
				if data, ok := args[0].(map[string]interface{}); ok {
					roomName, _ := data["roomName"].(string) // Converte o nome da sala para string
					if _, exists := rooms[roomName]; !exists {
						rooms[roomName] = NewRoom(roomName)
						roomDrawings[roomName] = &Drawing{}
						emitRoomList(io) // Atualiza a lista de salas para todos os clientes
						client.Emit("room:created", map[string]interface{}{"roomName": roomName})
					}
				}
			}
		})

		// Evento: Entrar na Sala
		client.On("room:join", func(args ...interface{}) {
			if len(args) > 1 {
				// Converta o primeiro argumento para map[string]interface{}
				data, ok := args[0].(map[string]interface{})
				if !ok {
					client.Emit("error", map[string]interface{}{"message": "Invalid data format"})
					return
				}

				// Converta o segundo argumento para função callback
				callback, ok := args[1].(func(map[string]interface{}))
				if !ok {
					client.Emit("error", map[string]interface{}{"message": "Invalid callback format"})
					return
				}

				// Extraia os dados do mapa
				roomName, _ := data["roomName"].(string)
				userId, _ := data["userId"].(string)
				username, _ := data["username"].(string)
				userAvatar, _ := data["userAvatar"].(string)

				// Lógica de entrada na sala
				if room, exists := rooms[roomName]; exists {
					if _, alreadyInRoom := room.Participants[userId]; !alreadyInRoom {
						participant := &Participant{
							UserId:      userId,
							Username:    username,
							UserAvatar:  userAvatar,
							IsLogged:    true,
							IsConnected: true,
						}
						room.AddParticipant(participant)

						// Converta roomName para socket.Room
						client.Join(socket.Room(roomName))

						// Converta client.Id() para string
						roomUsers[string(client.Id())] = roomName

						// Sincronizar o estado da sala com o cliente
						client.Emit("room:joined", map[string]interface{}{"roomName": roomName})
						io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]interface{}{
							"participants": room.GetParticipants(),
						})
						callback(map[string]interface{}{"success": true})
					} else {
						callback(map[string]interface{}{"success": false, "error": "User already in the room"})
					}
				} else {
					callback(map[string]interface{}{"success": false, "error": "Room does not exist"})
				}
			} else {
				client.Emit("error", map[string]interface{}{"message": "Invalid arguments"})
			}
		})

		// Evento: Sair da Sala
		client.On("room:leave", func(args ...interface{}) {
			if len(args) > 0 {
				// Converta o primeiro argumento para map[string]interface{}
				data, ok := args[0].(map[string]interface{})
				if !ok {
					client.Emit("error", map[string]interface{}{"message": "Invalid data format"})
					return
				}

				// Extraia os dados do mapa
				roomName, _ := data["roomName"].(string)
				userId, _ := data["userId"].(string)

				if room, exists := rooms[roomName]; exists {
					room.RemoveParticipant(userId)
					client.Leave(socket.Room(roomName))
					delete(roomUsers, string(client.Id()))

					// Atualiza os participantes na sala
					io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]interface{}{
						"participants": room.GetParticipants(),
					})

					// Verifica se a sala está vazia e remove-a
					if len(room.GetParticipants()) == 0 {
						delete(rooms, roomName)
						delete(roomDrawings, roomName)
						emitRoomList(io) // Atualiza a lista de salas para todos os clientes
					}
				}
			} else {
				client.Emit("error", map[string]interface{}{"message": "Invalid arguments"})
			}
		})

		// Evento: Início do traço
		client.On("drawing:stroke:start", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					client.Emit("error", map[string]interface{}{"message": "Invalid data format"})
					return
				}

				roomName, _ := data["roomName"].(string)
				stroke, _ := data["stroke"].(map[string]interface{})

				if drawing, exists := roomDrawings[roomName]; exists {
					parsedStroke := parseStroke(stroke)
					drawing.AddStroke(parsedStroke)
					io.To(socket.Room(roomName)).Emit("drawing:stroke:start", map[string]interface{}{"stroke": stroke})
				}
			}
		})

		// Evento: Últimos pontos do traço
		client.On("drawing:stroke:lastPoints", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					client.Emit("error", map[string]interface{}{"message": "Invalid data format"})
					return
				}

				roomName, _ := data["roomName"].(string)
				points, _ := data["strokeLastPoints"].([]map[string]interface{})

				if drawing, exists := roomDrawings[roomName]; exists {
					drawing.AddStrokeLastPoints(parsePoints(points))
					io.To(socket.Room(roomName)).Emit("drawing:stroke:lastPoints", map[string]interface{}{"strokeLastPoints": points})
				}
			}
		})

		// Evento: Limpar desenho
		client.On("drawing:clear", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					client.Emit("error", map[string]interface{}{"message": "Invalid data format"})
					return
				}

				roomName, _ := data["roomName"].(string)

				if drawing, exists := roomDrawings[roomName]; exists {
					drawing.Clear()
					io.To(socket.Room(roomName)).Emit("drawing:clear")
				}
			}
		})

		// Evento: Enviar mensagem para a sala
		client.On("chat:message", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					client.Emit("error", map[string]interface{}{"message": "Invalid data format"})
					return
				}

				roomName, _ := data["roomName"].(string)
				message := Message{
					Icon:     nil,
					UserId:   data["userId"].(string),
					Username: data["username"].(string),
					Text:     data["text"].(string),
				}

				if _, exists := rooms[roomName]; exists {
					io.To(socket.Room(roomName)).Emit("chat:message", message)
				}
			}
		})

		// Evento: Adivinhação de resposta
		client.On("chat:answer:guess", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					client.Emit("error", map[string]interface{}{"message": "Invalid data format"})
					return
				}

				roomName, _ := data["roomName"].(string)
				userId, _ := data["userId"].(string)
				username, _ := data["username"].(string)
				text, _ := data["text"].(string)

				room, exists := rooms[roomName]
				if !exists {
					client.Emit("error", ErrorDTO{
						Message: "Room does not exist.",
						Action:  "nothing",
					})
					return
				}

				correctWord := room.CurrentWord
				if correctWord == "" {
					client.Emit("error", ErrorDTO{
						Message: "No word is currently being drawn.",
						Action:  "nothing",
					})
					return
				}

				isCorrect := correctWord == text
				// error: undefined: Answer
				answer := Answer{
					Icon:      nil,
					UserId:    userId,
					Username:  username,
					Text:      text,
					IsCorrect: isCorrect,
				}

				io.To(socket.Room(roomName)).Emit("chat:answer:result", answer)

				if isCorrect {
					participant := room.Participants[userId]
					if participant != nil {
						points := 100
						participant.Score += points
						// error: room.ParticipantCorrectAnswer undefined (type *Room has no field or method ParticipantCorrectAnswer)
						room.ParticipantCorrectAnswer(userId)

						// error: room.HasEveryoneAnsweredCorrectly undefined (type *Room has no field or method HasEveryoneAnsweredCorrectly)
						if room.HasEveryoneAnsweredCorrectly() {
							// error: room.ResetCorrectAnswers undefined (type *Room has no field or method ResetCorrectAnswers)
							room.ResetCorrectAnswers()
							TurnManagerStartTurnTimer(io, roomName, 60)
						}
					}
				}
			}
		})

		// Evento: Iniciar turnos
		client.On("game:turns:start", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					client.Emit("error", map[string]interface{}{"message": "Invalid data format"})
					return
				}

				roomName, _ := data["roomName"].(string)
				room, exists := rooms[roomName]
				if !exists {
					client.Emit("error", ErrorDTO{
						Message: "Room does not exist.",
						Action:  "nothing",
					})
					return
				}

				if len(room.GetParticipants()) < 2 {
					client.Emit("error", ErrorDTO{
						Message: "Not enough players to start the game.",
						Action:  "nothing",
					})
					return
				}

				TurnManagerStartTurnTimer(io, roomName, 60)
			}
		})

		// Evento: Desconexão
		client.On("disconnect", func(...any) {
			roomName, userExists := roomUsers[string(client.Id())]
			if !userExists {
				return
			}

			room := rooms[roomName]
			if room == nil {
				return
			}

			participant := room.Participants[string(client.Id())]
			if participant != nil {
				participant.IsConnected = false
			}

			delete(roomUsers, string(client.Id()))

			// Verifica se a sala está vazia
			if len(room.GetParticipants()) == 0 {
				delete(rooms, roomName)
				delete(roomDrawings, roomName)
				io.Emit("room:all", map[string]any{
					"allRooms": getRoomNames(),
				})
			} else {
				io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]any{
					"participants": room.GetParticipants(),
				})
			}
		})

		// Evento: Solicitar ranking
		client.On("game:ranking", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					client.Emit("error", map[string]interface{}{"message": "Invalid data format"})
					return
				}

				roomName, _ := data["roomName"].(string)
				emitRanking(io, roomName)
			}
		})

		// log.Infof("Client connected: %s", string(client.Id()))

		// client.On("disconnect", func(...any) {
		// 	log.Infof("Client disconnected: %s", string(client.Id()))
		// })

		// client.On("error", func(data any) {
		// 	log.Errorf("Error: %v", data)
		// })
		//////
	})

	exit := make(chan struct{})
	SignalC := make(chan os.Signal)

	signal.Notify(SignalC, os.Interrupt, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)

	go func() {
		for s := range SignalC {
			switch s {
			case os.Interrupt, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT:
				close(exit)
				return
			}
		}
	}()

	<-exit
	io.Close(nil)
	os.Exit(0)
}

type Offset struct {
	Dx float64 `json:"dx"`
	Dy float64 `json:"dy"`
}

type Stroke struct {
	Points     []Offset `json:"points"`
	Color      int      `json:"color"`
	Size       int      `json:"size"`
	Opacity    float64  `json:"opacity"`
	StrokeType string   `json:"strokeType"`
	Filled     bool     `json:"filled"`
}

type Drawing struct {
	Strokes       []Stroke `json:"strokes"`
	BackupStrokes []Stroke `json:"backupStrokes"`
}

func (d *Drawing) AddStroke(stroke Stroke) {
	d.Strokes = append(d.Strokes, stroke)
}

func (d *Drawing) AddStrokeLastPoints(points []Offset) {
	if len(d.Strokes) > 0 {
		lastStroke := &d.Strokes[len(d.Strokes)-1]
		lastStroke.Points = append(lastStroke.Points, points...)
	}
}

func (d *Drawing) Clear() {
	d.Strokes = nil
	d.BackupStrokes = nil
}

func (d *Drawing) Undo() *Stroke {
	if len(d.Strokes) == 0 {
		return nil
	}
	lastStroke := d.Strokes[len(d.Strokes)-1]
	d.Strokes = d.Strokes[:len(d.Strokes)-1]
	d.BackupStrokes = append(d.BackupStrokes, lastStroke)
	return &lastStroke
}

func (d *Drawing) Redo() *Stroke {
	if len(d.BackupStrokes) == 0 {
		return nil
	}
	lastBackup := d.BackupStrokes[len(d.BackupStrokes)-1]
	d.BackupStrokes = d.BackupStrokes[:len(d.BackupStrokes)-1]
	d.Strokes = append(d.Strokes, lastBackup)
	return &lastBackup
}

type Participant struct {
	UserId      string `json:"userId"`
	Username    string `json:"username"`
	UserAvatar  string `json:"userAvatar"`
	IsLogged    bool   `json:"isLogged"`
	IsConnected bool   `json:"isConnected"`
	Score       int    `json:"score"`
}

type Room struct {
	Name                             string
	Participants                     map[string]*Participant
	TurnQueue                        []*Participant
	CurrentDrawerTurnIndex           int
	CurrentWord                      string
	TurnCount                        int
	ParticipantsWhoAnsweredCorrectly map[string]bool
}

func (r *Room) ParticipantCorrectAnswer(userId string) {
	if r.ParticipantsWhoAnsweredCorrectly == nil {
		r.ParticipantsWhoAnsweredCorrectly = make(map[string]bool)
	}
	r.ParticipantsWhoAnsweredCorrectly[userId] = true
}

func (r *Room) HasEveryoneAnsweredCorrectly() bool {
	currentDrawer := r.GetCurrentDrawer()
	for _, participant := range r.GetParticipants() {
		if participant.UserId != currentDrawer.UserId && participant.IsConnected {
			if !r.ParticipantsWhoAnsweredCorrectly[participant.UserId] {
				return false
			}
		}
	}
	return true
}

func (r *Room) GetCurrentDrawer() *Participant {
	if len(r.TurnQueue) == 0 {
		return nil
	}
	return r.TurnQueue[r.CurrentDrawerTurnIndex]
}

func (r *Room) ResetCorrectAnswers() {
	r.ParticipantsWhoAnsweredCorrectly = make(map[string]bool)
}

type Message struct {
	Icon     *string `json:"icon"`     // Ícone opcional
	UserId   string  `json:"userId"`   // ID do usuário
	Username string  `json:"username"` // Nome do usuário
	Text     string  `json:"text"`     // Texto da mensagem
}

type Answer struct {
	Icon      *string `json:"icon"`      // Ícone opcional (pode ser nil)
	UserId    string  `json:"userId"`    // ID do usuário
	Username  string  `json:"username"`  // Nome do usuário
	Text      string  `json:"text"`      // Texto da resposta
	IsCorrect bool    `json:"isCorrect"` // Indica se a resposta está correta
}

type Turn struct {
	Word                  string `json:"word"`                  // Palavra que está sendo desenhada
	Turn                  int    `json:"turn"`                  // Número do turno atual
	TotalDuration         int    `json:"totalDuration"`         // Duração total do turno em milissegundos
	CurrentDrawerUserId   string `json:"currentDrawerUserId"`   // ID do usuário que está desenhando
	CurrentDrawerUsername string `json:"currentDrawerUsername"` // Nome do usuário que está desenhando
}

type ErrorDTO struct {
	Message string `json:"message"` // Mensagem de erro
	Action  string `json:"action"`  // Ação sugerida (e.g., "nothing", "retry")
}

func NewRoom(name string) *Room {
	return &Room{
		Name:                             name,
		Participants:                     make(map[string]*Participant),
		ParticipantsWhoAnsweredCorrectly: make(map[string]bool),
	}
}

func (r *Room) AddParticipant(participant *Participant) {
	r.Participants[participant.UserId] = participant
	r.TurnQueue = append(r.TurnQueue, participant)
}

func (r *Room) RemoveParticipant(userId string) {
	delete(r.Participants, userId)
	var newQueue []*Participant
	for _, p := range r.TurnQueue {
		if p.UserId != userId {
			newQueue = append(newQueue, p)
		}
	}
	r.TurnQueue = newQueue
	if r.CurrentDrawerTurnIndex >= len(r.TurnQueue) {
		r.CurrentDrawerTurnIndex = 0
	}
}

func (r *Room) GetParticipants() []*Participant {
	participants := []*Participant{}
	for _, p := range r.Participants {
		participants = append(participants, p)
	}
	return participants
}

func (r *Room) AdvanceTurn() {
	r.TurnCount++
	r.CurrentDrawerTurnIndex = r.TurnCount % len(r.TurnQueue)
}

var (
	rooms        = make(map[string]*Room)    // Nome da sala -> Room
	roomDrawings = make(map[string]*Drawing) // Nome da sala -> Drawing
	roomUsers    = make(map[string]string)   // Socket ID -> RoomUserDTO
)

func getRoomNames() []string {
	names := make([]string, 0, len(rooms))
	for name := range rooms {
		names = append(names, name)
	}
	return names
}

func parseStroke(data map[string]any) Stroke {
	points := parsePoints(data["points"].([]map[string]any))
	return Stroke{
		Points:     points,
		Color:      int(data["color"].(float64)),
		Size:       int(data["size"].(float64)),
		Opacity:    data["opacity"].(float64),
		StrokeType: data["strokeType"].(string),
		Filled:     data["filled"].(bool),
	}
}

func parsePoints(data []map[string]any) []Offset {
	points := make([]Offset, len(data))
	for i, point := range data {
		points[i] = Offset{
			Dx: point["dx"].(float64),
			Dy: point["dy"].(float64),
		}
	}
	return points
}

func TurnManagerStartTurnTimer(io *socket.Server, roomName string, totalDuration int) {
	room, exists := rooms[roomName]
	if !exists {
		return
	}

	room.AdvanceTurn()
	room.ResetCorrectAnswers()

	drawing := roomDrawings[roomName]
	if drawing != nil {
		drawing.Clear()
	}

	currentDrawer := room.GetCurrentDrawer()
	if currentDrawer == nil {
		return
	}

	// Escolha uma palavra aleatória
	wordsList := []string{"gato", "cachorro", "casa", "carro", "árvore"}
	wordToDraw := wordsList[int(time.Now().Unix()%int64(len(wordsList)))]
	room.CurrentWord = wordToDraw
	// error: undefined: io
	io.To(socket.Room(roomName)).Emit("game:turn:new", Turn{
		Word:                  wordToDraw,
		Turn:                  room.TurnCount,
		TotalDuration:         totalDuration * 1000,
		CurrentDrawerUserId:   currentDrawer.UserId,
		CurrentDrawerUsername: currentDrawer.Username,
	})

	// error: undefined: io
	// Atualiza participantes
	io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]any{
		"participants": room.GetParticipants(),
	})

	// Cronômetro para o próximo turno
	go func() {
		time.Sleep(time.Duration(totalDuration) * time.Second)
		TurnManagerStartTurnTimer(io, roomName, totalDuration)
	}()
}

func emitRanking(io *socket.Server, roomName string) {
	room, exists := rooms[roomName]
	if !exists {
		return
	}

	// Calcular ranking
	ranking := make([]map[string]any, 0)
	participants := room.GetParticipants()

	for _, participant := range participants {
		ranking = append(ranking, map[string]any{
			"username": participant.Username,
			"score":    participant.Score,
		})
	}

	// Ordenar por pontuação decrescente
	sort.Slice(ranking, func(i, j int) bool {
		return ranking[i]["score"].(int) > ranking[j]["score"].(int)
	})

	// error: undefined: io
	io.To(socket.Room(roomName)).Emit("game:ranking", map[string]any{
		"ranking": ranking,
	})
}

func emitRoomList(io *socket.Server) {
	// error: undefined: io
	io.Emit("room:all", map[string]any{
		"allRooms": getRoomNames(),
	})
}
