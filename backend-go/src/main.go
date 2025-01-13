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

// Configurações do servidor
const (
	Version    = "0.50.2"
	MinPlayers = 2
	MaxPlayers = 4
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
					roomName, _ := data["roomName"].(string)
					createRoom(io, client, roomName)
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
					emitError(client, "Invalid data format", Nothing)
					return
				}

				// Extraindo e verificando o formato do callback
				rawCallback := args[1]
				callback, ok := rawCallback.(func([]interface{}, error))
				if !ok {
					fmt.Printf("Callback type assertion failed: %+v\n", rawCallback)
					emitError(client, "Invalid callback format", Nothing)
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
						"message": "Room does not exist",
					}}, nil)
					return
				}

				participant, alreadyInRoom := room.Participants[userId]
				if alreadyInRoom {
					participant.IsConnected = true

					client.Join(socket.Room(roomName))
					roomUsers[string(client.Id())] = &RoomUser{
						RoomName:   roomName,
						UserId:     userId,
						Username:   username,
						UserAvatar: &userAvatar,
						IsLogged:   true,
					}

					sendJoinMessage(io, roomName, userId, username)

					if drawing, exists := roomDrawings[roomName]; exists {
						emitDrawingState(io, roomName, drawing)
					}

					io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]interface{}{
						"participants": room.getParticipants(),
					})

					currentDrawer := validateCurrentDrawer(io, room, roomName)
					if currentDrawer == nil {
						return // Retorna se não houver desenhista válido
					}

					callback([]interface{}{map[string]interface{}{
						"success":             true,
						"turn":                room.TurnCount,
						"isGameStarted":       room.IsGameStarted,
						"currentDrawerUserId": currentDrawer.UserId,
						"message":             "Reconnected",
					}}, nil)
				} else {
					if len(room.getParticipants()) < MaxPlayers {
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

						room.addParticipant(participant)
						client.Join(socket.Room(roomName))
						roomUsers[string(client.Id())] = &RoomUser{
							RoomName:   roomName,
							UserId:     userId,
							Username:   username,
							UserAvatar: &userAvatar,
							IsLogged:   true,
						}

						sendJoinMessage(io, roomName, userId, username)

						if drawing, exists := roomDrawings[roomName]; exists {
							emitDrawingState(io, roomName, drawing)
						}

						io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]interface{}{
							"participants": room.getParticipants(),
						})

						currentDrawer := validateCurrentDrawer(io, room, roomName)
						if currentDrawer == nil {
							return // Retorna se não houver desenhista válido
						}

						callback([]interface{}{map[string]interface{}{
							"success":             true,
							"turn":                room.TurnCount,
							"isGameStarted":       room.IsGameStarted,
							"currentDrawerUserId": currentDrawer.UserId,
							"message":             "Joined room",
						}}, nil)
					} else {
						emitError(client, fmt.Sprintf("Room %s is full. Maximum %d players allowed.", roomName, MaxPlayers), Nothing)
						callback([]interface{}{map[string]interface{}{
							"success": false,
							"message": "Room is full",
						}}, nil)
					}
				}
			} else {
				emitError(client, "Invalid arguments", Nothing)
			}
		})

		// Evento: Sair da Sala
		client.On("room:leave", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", Nothing)
					return
				}

				roomName, _ := data["roomName"].(string)
				userId, _ := data["userId"].(string)

				if room, exists := rooms[roomName]; exists {
					room.removeParticipant(userId)
					client.Leave(socket.Room(roomName))
					delete(roomUsers, string(client.Id()))

					// Atualiza os participantes na sala
					io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]interface{}{
						"participants": room.getParticipants(),
					})

					// Remove a sala se não houver participantes
					if len(room.getParticipants()) == 0 {
						deleteRoom(roomName) // Chama deleteRoom para limpar os recursos
						emitRoomList(io)     // Atualiza a lista de salas para todos os clientes
					}
				}
			} else {
				emitError(client, "Invalid arguments", Nothing)
			}
		})

		// Evento: Início do traço
		client.On("drawing:stroke:start", func(args ...interface{}) {
			if len(args) == 0 {
				emitError(client, "No arguments provided", Nothing)
				return
			}

			data, ok := args[0].(map[string]interface{})
			if !ok {
				emitError(client, "Invalid data format", Nothing)
				return
			}

			roomName, _ := data["roomName"].(string)
			rawStroke, _ := data["stroke"].(map[string]interface{})

			stroke, err := parseStroke(rawStroke)
			if err != nil {
				emitError(client, fmt.Sprintf("Failed to parse stroke: %v", err), Nothing)
				return
			}

			if drawing, exists := roomDrawings[roomName]; exists {
				drawing.addStroke(stroke)
				io.To(socket.Room(roomName)).Emit("drawing:stroke:start", map[string]interface{}{"stroke": rawStroke})
			}
		})

		// Evento: Últimos pontos do traço
		client.On("drawing:stroke:lastPoints", func(args ...interface{}) {
			if len(args) > 0 {
				// Verifica se o argumento recebido é do tipo esperado
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", Nothing)
					return
				}

				roomName, _ := data["roomName"].(string)
				rawPoints, ok := data["strokeLastPoints"].([]interface{})
				if !ok {
					emitError(client, "Invalid strokeLastPoints format", Nothing)
					return
				}

				// Processa os pontos
				points, err := parsePoints(rawPoints)
				if err != nil {
					emitError(client, fmt.Sprintf("Failed to parse points: %v", err), Nothing)
					return
				}

				if drawing, exists := roomDrawings[roomName]; exists {
					drawing.addStrokeLastPoints(points)
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
					emitError(client, "Invalid data format", Nothing)
					return
				}

				roomName, _ := data["roomName"].(string)

				if drawing, exists := roomDrawings[roomName]; exists {
					drawing.clear()
					io.To(socket.Room(roomName)).Emit("drawing:clear")
				}
			}
		})

		// Evento: Undo
		client.On("drawing:undo", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", Nothing)
					return
				}

				roomName, _ := data["roomName"].(string)

				if drawing, exists := roomDrawings[roomName]; exists {
					lastStroke := drawing.undo()
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
					emitError(client, "Invalid data format", Nothing)
					return
				}

				roomName, _ := data["roomName"].(string)

				if drawing, exists := roomDrawings[roomName]; exists {
					lastStroke := drawing.redo()
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
					emitError(client, "Invalid data format", Nothing)
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
					emitError(client, "Invalid data format", Nothing)
					return
				}

				roomName, _ := data["roomName"].(string)
				userId, _ := data["userId"].(string)
				username, _ := data["username"].(string)
				text, _ := data["text"].(string)

				room, exists := rooms[roomName]
				if !exists || !room.IsGameStarted {
					emitError(client, "Game not started in this room.", Nothing)
					return
				}

				correctWord := room.CurrentWord
				if correctWord == "" {
					emitError(client, "No word is currently being drawn.", Nothing)
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
						rank := room.getCorrectAnswerRank(userId)

						// Calcula os pontos baseados na posição e no tempo restante
						basePoints := uint16(100 - (rank-1)*20) // Reduz pontos com base na posição
						timeLeft := room.TurnCount              // Tempo restante (ajuste para obter o valor real)
						bonus := timeLeft / 10                  // Bônus por rapidez
						points := max(basePoints+uint16(bonus), 10)

						participant.Score += points

						// Atualiza a pontuação do desenhista
						drawer := room.getCurrentDrawer()
						if drawer != nil {
							totalParticipants := uint8(len(room.getParticipants()) - 1) // Exclui o desenhista
							if totalParticipants > 0 {
								drawerPointsPerCorrectGuess := uint16(100 / totalParticipants)
								drawer.Score += drawerPointsPerCorrectGuess
							}
						}

						fmt.Printf("%s acertou! Ganhou %d pontos.\n", username, points)
						room.participantCorrectAnswer(userId)

						// Verifica se todos os participantes acertaram
						if room.hasEveryoneAnsweredCorrectly() {
							fmt.Printf("Todos os participantes da sala %s acertaram. Avançando turno.\n", roomName)
							room.resetCorrectAnswers()
							startTurnTimer(io, roomName, 60)
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
					emitError(client, "Room does not exist", Nothing)
					return
				}

				if len(room.getParticipants()) < MinPlayers {
					emitError(client, fmt.Sprintf("Not enough players. Minimum %d required.", MinPlayers), "retry")
					return
				}

				room.IsGameStarted = true
				startTurnTimer(io, roomName, 60)
			}
		})

		// Evento: Desconexão
		client.On("disconnect", func(...any) {
			userInfo, exists := roomUsers[string(client.Id())]
			if !exists {
				return
			}

			room, exists := rooms[userInfo.RoomName]
			if !exists {
				return
			}

			participant, participantExists := room.Participants[userInfo.UserId]
			if participantExists && participant != nil {
				participant.IsConnected = false // Marca o participante como desconectado

				// Emite mensagem para a sala sobre a saída do participante
				icon := "info"
				io.To(socket.Room(userInfo.RoomName)).Emit("chat:message", Message{
					Icon:     &icon,
					UserId:   participant.UserId,
					Username: participant.Username,
					Text:     "saiu",
				})

				// Adiciona o temporizador de 5 segundos
				time.AfterFunc(5*time.Second, func() {
					// Verifica se o participante ainda está desconectado
					if !participant.IsConnected {
						fmt.Printf("Removendo participante %s da sala %s após 5 segundos de desconexão.\n", participant.Username, room.Name)

						// Remove o participante do jogo
						room.removeParticipant(participant.UserId)

						// Ajusta os turnos se necessário
						if room.CurrentDrawerTurnIndex >= int8(len(room.TurnQueue)) {
							room.advanceTurn()
						}

						// Atualiza o estado do jogo
						io.To(socket.Room(room.Name)).Emit("room:participants:update", map[string]interface{}{
							"participants": room.getParticipants(),
						})

						if len(room.TurnQueue) == 0 {
							deleteRoom(room.Name) // Remove a sala se não houver mais participantes
							emitRoomList(io)
						} else if room.hasEveryoneAnsweredCorrectly() {
							startTurnTimer(io, room.Name, 60) // Avança o turno
						}
					}
				})
			}

			delete(roomUsers, string(client.Id())) // Remove o usuário do mapa global
		})

		// Evento: Solicitar ranking
		client.On("game:ranking", func(args ...interface{}) {
			if len(args) > 0 {
				data, ok := args[0].(map[string]interface{})
				if !ok {
					emitError(client, "Invalid data format", Nothing)
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

// ===================
// Funções de Desenho
// ===================
// Evento: Atualizar desenho completo
func emitDrawingState(io *socket.Server, roomName string, drawing *Drawing) {
	io.To(socket.Room(roomName)).Emit("drawing:stroke:all", map[string]interface{}{
		"strokes": drawing.Strokes,
	})
}

type StrokeType string

const (
	normal  StrokeType = "normal"
	eraser  StrokeType = "eraser"
	line    StrokeType = "line"
	polygon StrokeType = "polygon"
	square  StrokeType = "square"
	circle  StrokeType = "circle"
)

func ParseStrokeType(value string) (StrokeType, error) {
	switch StrokeType(value) {
	case normal, eraser, line, polygon, square, circle:
		return StrokeType(value), nil
	default:
		return "", fmt.Errorf("invalid stroke type: %s", value)
	}
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
	colorFloat64, ok := data["color"].(float64)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'color'")
	}
	// if colorFloat < 0 || colorFloat > 4294967295 {
	// 	return Stroke{}, fmt.Errorf("'color' value out of range for uint32")
	// }
	// color := uint32(colorFloat)

	sizeFloat64, ok := data["size"].(float64)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'size'")
	}

	opacityFloat64, ok := data["opacity"].(float64)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'opacity'")
	}

	rawType, ok := data["strokeType"].(string)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'strokeType'")
	}
	strokeType, err := ParseStrokeType(rawType)
	if err != nil {
		return Stroke{}, err
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
		Color:      uint32(colorFloat64),
		Size:       float32(sizeFloat64),
		Opacity:    uint8(opacityFloat64),
		StrokeType: strokeType,
		Filled:     filled,
	}, nil
}

func sendJoinMessage(io *socket.Server, roomName, userId, username string) {
	icon := "info"
	message := Message{
		Icon:     &icon,
		UserId:   userId,
		Username: username,
		Text:     "entrou",
	}
	io.To(socket.Room(roomName)).Emit("chat:message", message)
}

// ===================
// Funções de Gerenciamento de Salas
// ===================
// Função para criar uma nova sala
func newRoom(name string) *Room {
	return &Room{
		Name:                             name,
		Participants:                     make(map[string]*Participant),
		ParticipantsWhoAnsweredCorrectly: make(map[string]bool),
	}
}

func createRoom(io *socket.Server, client *socket.Socket, roomName string) {
	if _, exists := rooms[roomName]; !exists {
		rooms[roomName] = newRoom(roomName)
		roomDrawings[roomName] = &Drawing{}
		emitRoomList(io) // Atualiza a lista de salas
		client.Emit("room:created", map[string]interface{}{"roomName": roomName})
	}
}

func deleteRoom(roomName string) {
	room, exists := rooms[roomName]
	if exists {
		cancelActiveTimer(room)
		room.IsGameStarted = false
		delete(rooms, roomName)
		delete(roomDrawings, roomName)
	}
}

func emitErrorToRoom(io *socket.Server, roomName string, message string, action ErrorActionType) {
	io.To(socket.Room(roomName)).Emit("error", ErrorDTO{
		Message: message,
		Action:  action,
	})
}

// ===================
// Funções de Room
// ===================
func (r *Room) participantCorrectAnswer(userId string) {
	if r.ParticipantsWhoAnsweredCorrectly == nil {
		r.ParticipantsWhoAnsweredCorrectly = make(map[string]bool)
	}
	r.ParticipantsWhoAnsweredCorrectly[userId] = true
}

func (r *Room) hasEveryoneAnsweredCorrectly() bool {
	currentDrawer := r.getCurrentDrawer()
	for _, participant := range r.getParticipants() {
		// Ignorar o desenhista e verificar apenas os conectados
		if participant.UserId != currentDrawer.UserId && participant.IsConnected {
			if !r.ParticipantsWhoAnsweredCorrectly[participant.UserId] {
				return false
			}
		}
	}
	return true
}

func (r *Room) getCurrentDrawer() *Participant {
	if r.CurrentDrawerTurnIndex == -1 || len(r.TurnQueue) == 0 {
		return nil
	}
	return r.TurnQueue[r.CurrentDrawerTurnIndex]
}

func (r *Room) resetCorrectAnswers() {
	r.ParticipantsWhoAnsweredCorrectly = make(map[string]bool)
}

func (r *Room) addParticipant(participant *Participant) {
	r.Participants[participant.UserId] = participant
	r.TurnQueue = append(r.TurnQueue, participant)
}

func (r *Room) removeParticipant(userId string) {
	delete(r.Participants, userId)

	var newQueue []*Participant
	for _, p := range r.TurnQueue {
		if p.UserId != userId {
			newQueue = append(newQueue, p)
		}
	}

	r.TurnQueue = newQueue

	// Ajusta o índice do desenhista atual
	if len(r.TurnQueue) == 0 {
		r.CurrentDrawerTurnIndex = -1 // Nenhum desenhista disponível
	} else if r.CurrentDrawerTurnIndex >= int8(len(r.TurnQueue)) {
		r.advanceTurn() // Avança o turno
	}
}

func (r *Room) getParticipants() []*Participant {
	participants := []*Participant{}
	for _, p := range r.Participants {
		participants = append(participants, p)
	}
	// cannot use (func(i, j uint8) bool literal) (value of type func(i uint8, j uint8) bool) as func(i int, j int) bool value in argument to sort.Slice
	sort.Slice(participants, func(i, j int) bool {
		if participants[i].Score == participants[j].Score {
			return participants[i].PreviousOrder < participants[j].PreviousOrder
		}
		return participants[i].Score > participants[j].Score
	})

	for idx, participant := range participants {
		participant.PreviousOrder = uint8(idx)
	}

	return participants
}

func (r *Room) advanceTurn() {
	if len(r.TurnQueue) == 0 {
		return
	}

	r.TurnCount++
	startIdx := r.CurrentDrawerTurnIndex // Guarda o ponto inicial para evitar loops infinitos

	for {
		r.CurrentDrawerTurnIndex = (r.CurrentDrawerTurnIndex + 1) % int8(len(r.TurnQueue))
		currentDrawer := r.TurnQueue[r.CurrentDrawerTurnIndex]

		// Verifica se o participante está conectado
		if currentDrawer.IsConnected {
			break
		}

		// Se percorremos todos os participantes sem encontrar um conectado
		if r.CurrentDrawerTurnIndex == startIdx {
			fmt.Println("Nenhum participante conectado para ser o desenhista.")
			r.CurrentDrawerTurnIndex = -1 // Define como inválido se não houver conectados
			return
		}
	}
}

func (r *Room) getCorrectAnswerRank(userId string) uint8 {
	if r.ParticipantsWhoAnsweredCorrectly == nil {
		r.ParticipantsWhoAnsweredCorrectly = make(map[string]bool)
	}

	// Verifica se o participante já respondeu corretamente
	var rank uint8 = 1
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

// ===================
// Funções de Drawing
// ===================
func (d *Drawing) addStroke(stroke Stroke) {
	d.Strokes = append(d.Strokes, stroke)
}

func (d *Drawing) addStrokeLastPoints(points []Offset) {
	if len(d.Strokes) > 0 {
		lastStroke := &d.Strokes[len(d.Strokes)-1]
		lastStroke.Points = append(lastStroke.Points, points...)
	}
}

func (d *Drawing) clear() {
	d.Strokes = nil
	d.BackupStrokes = nil
}

func (d *Drawing) undo() *Stroke {
	if len(d.Strokes) == 0 {
		return nil
	}
	lastStroke := d.Strokes[len(d.Strokes)-1]
	d.Strokes = d.Strokes[:len(d.Strokes)-1]
	d.BackupStrokes = append(d.BackupStrokes, lastStroke)
	return &lastStroke
}

func (d *Drawing) redo() *Stroke {
	if len(d.BackupStrokes) == 0 {
		return nil
	}
	lastBackup := d.BackupStrokes[len(d.BackupStrokes)-1]
	d.BackupStrokes = d.BackupStrokes[:len(d.BackupStrokes)-1]
	d.Strokes = append(d.Strokes, lastBackup)
	return &lastBackup
}

// ===================
// ???
// ===================
var (
	rooms        = make(map[string]*Room)     // Nome da sala -> Room
	roomDrawings = make(map[string]*Drawing)  // Nome da sala -> Drawing
	roomUsers    = make(map[string]*RoomUser) // Socket ID -> RoomUserInfo
)

func getRoomNames() []string {
	names := make([]string, 0, len(rooms))
	for name := range rooms {
		names = append(names, name)
	}
	return names
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

func startTurnTimer(io *socket.Server, roomName string, totalDuration uint32) {
	room, exists := rooms[roomName]
	if !exists {
		return
	}

	// Cancela o timer anterior, se existir
	cancelActiveTimer(room)

	room.advanceTurn()

	currentDrawer := validateCurrentDrawer(io, room, roomName)
	if currentDrawer == nil {
		return // Retorna se não houver desenhista válido
	}

	// Resetar estado para o novo turno
	room.resetCorrectAnswers()
	roomDrawings[roomName].clear()

	wordToDraw := chooseRandomWord()
	room.CurrentWord = wordToDraw

	io.To(socket.Room(roomName)).Emit("game:turn:new", Turn{
		Word:                  wordToDraw,
		Turn:                  room.TurnCount,
		TotalDuration:         totalDuration * 1000,
		CurrentDrawerUserId:   currentDrawer.UserId,
		CurrentDrawerUsername: currentDrawer.Username,
		IsGameStarted:         room.IsGameStarted,
	})

	io.To(socket.Room(roomName)).Emit("room:participants:update", map[string]any{
		"participants": room.getParticipants(),
	})

	// Configura o novo timer
	room.ActiveTimer = time.AfterFunc(time.Duration(totalDuration)*time.Second, func() {
		fmt.Printf("Timer executado para a sala %s.\n", roomName)
		startTurnTimer(io, roomName, totalDuration)
	})
	fmt.Printf("Novo timer configurado para a sala %s.\n", roomName)
}

func cancelActiveTimer(room *Room) {
	if room.ActiveTimer != nil {
		room.ActiveTimer.Stop()
		room.ActiveTimer = nil
	}
}

var wordsList = []string{
	"r",
	// "gato", "cachorro", "casa", "carro", "árvore", "flor", "sol", "lua",
	// "livro", "avião", "rio", "montanha", "praia", "peixe", "pássaro",
	// "computador", "telefone", "cadeira", "mesa", "namorados", "corda",
	// "futebol", "bola", "cama", "travesseiro", "cobertor", "chave", "porta",
}

func validateCurrentDrawer(io *socket.Server, room *Room, roomName string) *Participant {
	currentDrawer := room.getCurrentDrawer()
	if currentDrawer == nil {
		fmt.Printf("Não há participantes conectados na sala %s.\n", roomName)
		emitErrorToRoom(io, roomName, "Nenhum participante conectado para ser o desenhista.", Dialog)
		return nil
	}
	return currentDrawer
}

func chooseRandomWord() string {
	if len(wordsList) == 0 {
		return "Nenhuma palavra disponível."
	}
	randomIndex := time.Now().UnixNano() % int64(len(wordsList))
	return wordsList[randomIndex]
}

func emitRanking(io *socket.Server, roomName string) {
	room, exists := rooms[roomName]
	if !exists {
		return
	}

	// Calcular ranking
	ranking := make([]map[string]any, 0)
	participants := room.getParticipants()

	for _, participant := range participants {
		ranking = append(ranking, map[string]any{
			"username": participant.Username,
			"score":    participant.Score,
		})
	}

	// Ordenar por pontuação decrescente
	// cannot use (func(i, j uint8) bool literal) (value of type func(i uint8, j uint8) bool) as func(i int, j int) bool value in argument to sort.Slice
	sort.Slice(ranking, func(i, j int) bool {
		return ranking[i]["score"].(uint16) > ranking[j]["score"].(uint16)
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

func emitError(client *socket.Socket, message string, action ErrorActionType) {
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
	Points     []Offset   `json:"points"`
	Color      uint32     `json:"color"`
	Size       float32    `json:"size"`
	Opacity    uint8      `json:"opacity"`
	StrokeType StrokeType `json:"strokeType"`
	Filled     *bool      `json:"filled"`
}

type Room struct {
	Name                             string
	Participants                     map[string]*Participant
	TurnQueue                        []*Participant
	CurrentDrawerTurnIndex           int8
	CurrentWord                      string
	TurnCount                        uint8
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
	Score         uint16  `json:"score"`
	PreviousOrder uint8   `json:"-"`
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
	Turn                  uint8  `json:"turn"`                  // Número do turno atual
	TotalDuration         uint32 `json:"totalDuration"`         // Duração total do turno em milissegundos
	CurrentDrawerUserId   string `json:"currentDrawerUserId"`   // ID do usuário que está desenhando
	CurrentDrawerUsername string `json:"currentDrawerUsername"` // Nome do usuário que está desenhando
	IsGameStarted         bool   `json:"isGameStarted"`
}

type ErrorActionType string

const (
	Nothing ErrorActionType = "nothing"
	Retry   ErrorActionType = "retry"
	Ignore  ErrorActionType = "ignore"
	Log     ErrorActionType = "log"
	Pop     ErrorActionType = "pop"
	Dialog  ErrorActionType = "dialog"
)

// Validação do enum
func isValidErrorActionType(action ErrorActionType) bool {
	switch action {
	case Nothing, Retry, Ignore, Log, Pop, Dialog:
		return true
	default:
		return false
	}
}

type ErrorDTO struct {
	Message string          `json:"message"`
	Action  ErrorActionType `json:"action"`
}

type RoomUser struct {
	RoomName   string  `json:"roomName"`
	UserId     string  `json:"userId"`
	Username   string  `json:"username"`
	UserAvatar *string `json:"userAvatar"`
	IsLogged   bool    `json:"isLogged"`
}

func logInfo(message string, args ...interface{}) {
	fmt.Printf("[INFO] "+message+"\n", args...)
}

func logError(message string, args ...interface{}) {
	fmt.Printf("[ERROR] "+message+"\n", args...)
}
