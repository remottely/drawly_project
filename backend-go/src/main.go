package main

import (
	"fmt"
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

const Version = "0.40.0"

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
			fmt.Printf("Args received: %+v\n", args)

			if len(args) > 1 {
				// Extraindo e verificando o formato do primeiro argumento
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", "nothing")
					return
				}

				// Extraindo e verificando o formato do callback
				rawCallback := args[1]
				callback, ok := rawCallback.(func([]interface{}, error))
				if !ok {
					fmt.Printf("Callback type assertion failed: %+v\n", rawCallback)
					emitError(client, "Invalid callback format", "nothing")
					return
				}

				roomName, _ := data["roomName"].(string)
				userId, _ := data["userId"].(string)
				username, _ := data["username"].(string)
				userAvatar, _ := data["userAvatar"].(string)

				room, exists := rooms[roomName]
				if !exists {
					callback([]interface{}{map[string]interface{}{
						"success": false,
						"error":   "Room does not exist",
					}}, nil)
					return
				}

				participant, alreadyInRoom := room.Participants[userId]
				if alreadyInRoom {
					participant.IsConnected = true
					io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]interface{}{
						"participants": room.GetParticipants(),
					})
					callback([]interface{}{map[string]interface{}{
						"success": false,
						"message": "Reconnected",
					}}, nil)
				} else {
					if len(room.GetParticipants()) < maxPlayers {
						participant := &Participant{
							UserId:   userId,
							Username: username,
							UserAvatar: func(avatar string) *string {
								if avatar == "" {
									return nil
								}
								return &avatar
							}(userAvatar),
							IsLogged:    true,
							IsConnected: true,
						}
						room.AddParticipant(participant)
						client.Join(socket.Room(roomName))
						roomUsers[string(client.Id())] = roomName

						icon := "info"
						message := Message{
							Icon:     &icon,
							UserId:   userId,
							Username: username,
							Text:     "entrou",
						}

						io.To(socket.Room(roomName)).Emit("chat:message", message)

						if drawing, exists := roomDrawings[roomName]; exists {
							emitDrawingState(io, roomName, drawing)
						}

						io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]interface{}{
							"participants": room.GetParticipants(),
						})
						callback([]interface{}{map[string]interface{}{
							"success":       true,
							"turn":          room.TurnCount,
							"isGameStarted": room.IsGameStarted,
						}}, nil)
					} else {
						emitError(client, fmt.Sprintf("Room %s is full. Maximum %d players allowed.", roomName, maxPlayers), "nothing")
						callback([]interface{}{map[string]interface{}{
							"success": false,
							"error":   "Room is full",
						}}, nil)
					}
				}
			} else {
				emitError(client, "Invalid arguments", "nothing")
			}
		})

		// Evento: Sair da Sala
		client.On("room:leave", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", "nothing")
					return
				}

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

					// Remove a sala se não houver participantes
					if len(room.GetParticipants()) == 0 {
						deleteRoom(roomName) // Chama deleteRoom para limpar os recursos
						emitRoomList(io)     // Atualiza a lista de salas para todos os clientes
					}
				}
			} else {
				emitError(client, "Invalid arguments", "nothing")
			}
		})

		// Evento: Início do traço
		client.On("drawing:stroke:start", func(args ...interface{}) {
			if len(args) == 0 {
				emitError(client, "No arguments provided", "nothing")
				return
			}

			data, ok := args[0].(map[string]interface{})
			if !ok {
				emitError(client, "Invalid data format", "nothing")
				return
			}

			roomName, _ := data["roomName"].(string)
			rawStroke, _ := data["stroke"].(map[string]interface{})

			stroke, err := parseStroke(rawStroke)
			if err != nil {
				emitError(client, fmt.Sprintf("Failed to parse stroke: %v", err), "nothing")
				return
			}

			if drawing, exists := roomDrawings[roomName]; exists {
				drawing.AddStroke(stroke)
				io.To(socket.Room(roomName)).Emit("drawing:stroke:start", map[string]interface{}{"stroke": rawStroke})
			}
		})

		// Evento: Últimos pontos do traço
		client.On("drawing:stroke:lastPoints", func(args ...interface{}) {
			if len(args) > 0 {
				// Verifica se o argumento recebido é do tipo esperado
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", "nothing")
					return
				}

				roomName, _ := data["roomName"].(string)
				rawPoints, ok := data["strokeLastPoints"].([]interface{})
				if !ok {
					emitError(client, "Invalid strokeLastPoints format", "nothing")
					return
				}

				// Processa os pontos
				points, err := parsePoints(rawPoints)
				if err != nil {
					emitError(client, fmt.Sprintf("Failed to parse points: %v", err), "nothing")
					return
				}

				if drawing, exists := roomDrawings[roomName]; exists {
					drawing.AddStrokeLastPoints(points)
					io.To(socket.Room(roomName)).Emit("drawing:stroke:lastPoints", map[string]interface{}{
						"strokeLastPoints": rawPoints,
					})
				}
			}
		})

		// Evento: Limpar desenho
		client.On("drawing:clear", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", "nothing")
					return
				}

				roomName, _ := data["roomName"].(string)

				if drawing, exists := roomDrawings[roomName]; exists {
					drawing.Clear()
					io.To(socket.Room(roomName)).Emit("drawing:clear")
				}
			}
		})

		// Evento: Undo
		client.On("drawing:undo", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", "nothing")
					return
				}

				roomName, _ := data["roomName"].(string)

				if drawing, exists := roomDrawings[roomName]; exists {
					lastStroke := drawing.Undo()
					io.To(socket.Room(roomName)).Emit("drawing:undo", map[string]interface{}{
						"stroke": lastStroke,
					})
				}
			}
		})

		// Evento: Redo
		client.On("drawing:redo", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", "nothing")
					return
				}

				roomName, _ := data["roomName"].(string)

				if drawing, exists := roomDrawings[roomName]; exists {
					lastStroke := drawing.Redo()
					io.To(socket.Room(roomName)).Emit("drawing:redo", map[string]interface{}{
						"stroke": lastStroke,
					})
				}
			}
		})

		// Evento: Enviar mensagem para a sala
		client.On("chat:message", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", "nothing")
					return
				}

				roomName, _ := data["roomName"].(string)
				// icon, _ := data["icon"].(string)
				message := Message{
					// Icon:     &icon,
					Icon:     nil,
					UserId:   data["userId"].(string),
					Username: data["username"].(string),
					Text:     data["text"].(string),
				}

				io.To(socket.Room(roomName)).Emit("chat:message", message)
			}
		})

		// Evento: Adivinhação de resposta
		client.On("chat:answer:guess", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", "nothing")
					return
				}

				roomName, _ := data["roomName"].(string)
				userId, _ := data["userId"].(string)
				username, _ := data["username"].(string)
				text, _ := data["text"].(string)

				room, exists := rooms[roomName]
				if !exists || !room.IsGameStarted {
					emitError(client, "Game not started in this room.", "nothing")
					return
				}

				correctWord := room.CurrentWord
				if correctWord == "" {
					emitError(client, "No word is currently being drawn.", "nothing")
					return
				}

				isCorrect := correctWord == text
				var icon *string
				if isCorrect {
					value := "check"
					icon = &value
				} else {
					icon = nil
				}

				answer := Answer{
					Icon:      icon,
					UserId:    userId,
					Username:  username,
					Text:      text,
					IsCorrect: isCorrect,
				}

				io.To(socket.Room(roomName)).Emit("chat:answer:result", answer)

				if isCorrect {
					participant := room.Participants[userId]
					if participant != nil {
						// Obtém a posição na ordem de respostas corretas
						rank := room.GetCorrectAnswerRank(userId)

						// Calcula os pontos baseados na posição e no tempo restante
						basePoints := 100 - (rank-1)*20 // Reduz pontos com base na posição
						timeLeft := room.TurnCount      // Tempo restante (ajuste para obter o valor real)
						bonus := timeLeft / 10          // Bônus por rapidez
						points := max(basePoints+bonus, 10)

						participant.Score += points

						// Atualiza a pontuação do desenhista
						drawer := room.GetCurrentDrawer()
						if drawer != nil {
							totalParticipants := len(room.GetParticipants()) - 1 // Exclui o desenhista
							if totalParticipants > 0 {
								drawerPointsPerCorrectGuess := 100 / totalParticipants
								drawer.Score += drawerPointsPerCorrectGuess
							}
						}

						fmt.Printf("%s acertou! Ganhou %d pontos.\n", username, points)
						room.ParticipantCorrectAnswer(userId)

						// Verifica se todos os participantes acertaram
						if room.HasEveryoneAnsweredCorrectly() {
							fmt.Printf("Todos os participantes da sala %s acertaram. Avançando turno.\n", roomName)
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
					emitError(client, "Invalid data format", "retry")
					return
				}

				roomName, _ := data["roomName"].(string)
				room, exists := rooms[roomName]
				if !exists {
					emitError(client, "Room does not exist", "nothing")
					return
				}

				if len(room.GetParticipants()) < minPlayers {
					emitError(client, fmt.Sprintf("Not enough players. Minimum %d required.", minPlayers), "retry")
					return
				}

				room.IsGameStarted = true
				TurnManagerStartTurnTimer(io, roomName, 60)
			}
		})

		// Evento: Desconexão
		client.On("disconnect", func(...any) {
			roomName, userExists := roomUsers[string(client.Id())]
			if !userExists {
				return
			}

			room, exists := rooms[roomName]
			if !exists || room == nil {
				return
			}

			participant, participantExists := room.Participants[string(client.Id())]
			if participantExists && participant != nil {
				participant.IsConnected = false // Marca o participante como desconectado

				// Emite mensagem para a sala sobre a saída do participante
				io.To(socket.Room(roomName)).Emit("chat:message", Message{
					Icon:     nil,
					UserId:   participant.UserId,
					Username: participant.Username,
					Text:     "saiu",
				})
			}

			delete(roomUsers, string(client.Id())) // Remove o usuário do mapa global

			// Verifica se todos os participantes conectados responderam corretamente
			if room.HasEveryoneAnsweredCorrectly() {
				fmt.Printf("Todos os participantes conectados na sala %s responderam corretamente.\n", roomName)
				room.ResetCorrectAnswers()
				TurnManagerStartTurnTimer(io, roomName, 60) // Avança para o próximo turno
			}

			// Se não há mais participantes conectados, remove a sala
			if len(room.GetParticipants()) == 0 {
				deleteRoom(roomName) // Remove a sala e seus recursos associados
				emitRoomList(io)     // Atualiza a lista de salas para todos os clientes
			} else {
				// Atualiza a lista de participantes na sala
				io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]interface{}{
					"participants": room.GetParticipants(),
				})
			}
		})

		// Evento: Solicitar ranking
		client.On("game:ranking", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", "nothing")
					return
				}

				roomName, _ := data["roomName"].(string)
				emitRanking(io, roomName)
			}
		})

		// fmt.Printf("Client connected: %s", string(client.Id()))

		// client.On("disconnect", func(...any) {
		// 	fmt.Printf("Client disconnected: %s", string(client.Id()))
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

const (
	minPlayers = 2
	maxPlayers = 4
)

// Evento: Atualizar desenho completo
func emitDrawingState(io *socket.Server, roomName string, drawing *Drawing) {
	io.To(socket.Room(roomName)).Emit("drawing:stroke:all", map[string]interface{}{
		"strokes": drawing.Strokes,
	})

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

func (r *Room) ParticipantCorrectAnswer(userId string) {
	if r.ParticipantsWhoAnsweredCorrectly == nil {
		r.ParticipantsWhoAnsweredCorrectly = make(map[string]bool)
	}
	r.ParticipantsWhoAnsweredCorrectly[userId] = true
}

func (r *Room) HasEveryoneAnsweredCorrectly() bool {
	currentDrawer := r.GetCurrentDrawer()
	for _, participant := range r.GetParticipants() {
		// Ignorar o desenhista e verificar apenas os conectados
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

	sort.Slice(participants, func(i, j int) bool {
		if participants[i].Score == participants[j].Score {
			return participants[i].PreviousOrder < participants[j].PreviousOrder
		}
		return participants[i].Score > participants[j].Score
	})

	for idx, participant := range participants {
		participant.PreviousOrder = idx
	}

	return participants
}

func (r *Room) AdvanceTurn() {
	r.TurnCount++
	r.CurrentDrawerTurnIndex = r.TurnCount % len(r.TurnQueue)
}

func (r *Room) GetCorrectAnswerRank(userId string) int {
	if r.ParticipantsWhoAnsweredCorrectly == nil {
		r.ParticipantsWhoAnsweredCorrectly = make(map[string]bool)
	}

	// Verifica se o participante já respondeu corretamente
	rank := 1
	for answeredUserId := range r.ParticipantsWhoAnsweredCorrectly {
		if answeredUserId == userId {
			return rank // Retorna a posição se já respondeu
		}
		rank++
	}

	// Se não respondeu, adiciona ao mapa e retorna a última posição
	r.ParticipantsWhoAnsweredCorrectly[userId] = true
	return rank
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

func parseStroke(data map[string]any) (Stroke, error) {
	// Validar e extrair os pontos
	rawPoints, ok := data["points"].([]any)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'points'")
	}

	points := make([]Offset, len(rawPoints))
	for i, rawPoint := range rawPoints {
		pointMap, ok := rawPoint.(map[string]any)
		if !ok {
			return Stroke{}, fmt.Errorf("invalid point format at index %d", i)
		}

		dx, dxOk := pointMap["dx"].(float64)
		dy, dyOk := pointMap["dy"].(float64)

		if !dxOk || !dyOk {
			return Stroke{}, fmt.Errorf("missing or invalid 'dx' or 'dy' at index %d", i)
		}

		points[i] = Offset{Dx: dx, Dy: dy}
	}

	// Validar e extrair outras propriedades
	color, ok := data["color"].(float64)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'color'")
	}

	size, ok := data["size"].(float64)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'size'")
	}

	opacity, ok := data["opacity"].(float64)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'opacity'")
	}

	strokeType, ok := data["strokeType"].(string)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'strokeType'")
	}

	// Campo 'Filled' opcional
	var filled *bool
	if rawFilled, exists := data["filled"]; exists {
		if filledValue, ok := rawFilled.(bool); ok {
			filled = &filledValue
		} else {
			return Stroke{}, fmt.Errorf("invalid 'filled' value")
		}
	}

	// Retorna o objeto Stroke
	return Stroke{
		Points:     points,
		Color:      int(color),
		Size:       int(size),
		Opacity:    opacity,
		StrokeType: strokeType,
		Filled:     filled,
	}, nil
}

func parsePoints(rawPoints []interface{}) ([]Offset, error) {
	points := make([]Offset, len(rawPoints))

	for i, raw := range rawPoints {
		point, ok := raw.(map[string]interface{})
		if !ok {
			return nil, fmt.Errorf("invalid point format at index %d, expected map[string]interface{} but got %T", i, raw)
		}

		dx, dxOk := point["dx"].(float64)
		dy, dyOk := point["dy"].(float64)
		if !dxOk || !dyOk {
			return nil, fmt.Errorf("missing or invalid 'dx' or 'dy' in point at index %d", i)
		}

		points[i] = Offset{Dx: dx, Dy: dy}
	}

	return points, nil
}

func TurnManagerStartTurnTimer(io *socket.Server, roomName string, totalDuration int) {
	room, exists := rooms[roomName]
	if !exists {
		return
	}

	// Cancela o timer anterior se existir
	if room.ActiveTimer != nil {
		room.ActiveTimer.Stop()
		room.ActiveTimer = nil
	}

	// Configura o novo turno
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
	wordsList := []string{
		"r",
		// "gato", "cachorro", "casa", "carro", "árvore", "flor", "sol", "lua", "livro", "avião",
		// "rio","montanha", "praia", "peixe", "pássaro", "computador", "telefone", "cadeira", "mesa",
		// "namorados", "corda", "pular", "futebol", "bola", "cama", "travesseiro", "cobertor", "chave", "porta",
	}
	wordToDraw := wordsList[int(time.Now().Unix()%int64(len(wordsList)))]
	room.CurrentWord = wordToDraw

	io.To(socket.Room(roomName)).Emit("game:turn:new", Turn{
		Word:                  wordToDraw,
		Turn:                  room.TurnCount,
		TotalDuration:         totalDuration * 1000,
		CurrentDrawerUserId:   currentDrawer.UserId,
		CurrentDrawerUsername: currentDrawer.Username,
		IsGameStarted:         room.IsGameStarted,
	})

	// Atualiza os participantes
	io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]any{
		"participants": room.GetParticipants(),
	})

	// Configura o novo timer
	room.ActiveTimer = time.AfterFunc(time.Duration(totalDuration)*time.Second, func() {
		room.ActiveTimer = nil // Timer concluído, zera a referência
		TurnManagerStartTurnTimer(io, roomName, totalDuration)
	})
}

func CancelActiveTimer(room *Room) {
	if room.ActiveTimer != nil {
		room.ActiveTimer.Stop()
		room.ActiveTimer = nil
	}
}

func deleteRoom(roomName string) {
	room, exists := rooms[roomName]
	if exists {
		CancelActiveTimer(room)
		room.IsGameStarted = false
		delete(rooms, roomName)
		delete(roomDrawings, roomName)
	}
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

	io.To(socket.Room(roomName)).Emit("game:ranking", map[string]any{
		"ranking": ranking,
	})
}

func emitRoomList(io *socket.Server) {

	io.Emit("room:all", map[string]any{
		"allRooms": getRoomNames(),
	})
}

func emitError(client *socket.Socket, message, action string) {
	client.Emit("error", ErrorDTO{
		Message: message,
		Action:  action,
	})
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
	Filled     *bool    `json:"filled"`
}

type Room struct {
	Name                             string
	Participants                     map[string]*Participant
	TurnQueue                        []*Participant
	CurrentDrawerTurnIndex           int
	CurrentWord                      string
	TurnCount                        int
	ParticipantsWhoAnsweredCorrectly map[string]bool
	ActiveTimer                      *time.Timer
	IsGameStarted                    bool
}

type Participant struct {
	UserId        string  `json:"userId"`
	Username      string  `json:"username"`
	UserAvatar    *string `json:"userAvatar"`
	IsLogged      bool    `json:"isLogged"`
	IsConnected   bool    `json:"isConnected"`
	Score         int     `json:"score"`
	PreviousOrder int     `json:"-"` // Ordem da rodada anterior
}

type Drawing struct {
	Strokes       []Stroke `json:"strokes"`
	BackupStrokes []Stroke `json:"backupStrokes"`
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
	IsGameStarted         bool   `json:"isGameStarted"`
}

type ErrorDTO struct {
	Message string `json:"message"` // Mensagem de erro
	Action  string `json:"action"`  // Ação sugerida (e.g., "nothing", "nothing")
}
