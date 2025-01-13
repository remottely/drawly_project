package main

import (
	"fmt"
	"time"

	"github.com/zishang520/socket.io/v2/socket"
)

const (
	MinPlayers = 2
	MaxPlayers = 4
)

func handleConnection(io *socket.Server, client *socket.Socket) {

	// Evento: Criar Sala
	client.On("room:create", func(args ...interface{}) {
		handleCreateRoom(io, client, args...)
	})

	// Evento: Entrar na Sala
	client.On("room:join", func(args ...interface{}) {
		handleJoinRoom(io, client, args...)
	})

	// Evento: Sair da Sala
	client.On("room:leave", func(args ...interface{}) {
		handleLeaveRoom(io, client, args...)
	})

	// Evento: Início do traço
	client.On("drawing:stroke:start", func(args ...interface{}) {
		handleStartStrokeDrawing(io, client, args...)
	})

	// Evento: Últimos pontos do traço
	client.On("drawing:stroke:lastPoints", func(args ...interface{}) {
		handleLastPointsStrokeDrawing(io, client, args...)
	})

	// Evento: Limpar desenho
	client.On("drawing:clear", func(args ...interface{}) {
		handleClearDrawing(io, client, args...)
	})

	// Evento: Undo
	client.On("drawing:undo", func(args ...interface{}) {
		handleUndoDrawing(io, client, args...)
	})

	// Evento: Redo
	client.On("drawing:redo", func(args ...interface{}) {
		handleRedoDrawing(io, client, args...)
	})

	// Evento: Enviar mensagem para a sala
	client.On("chat:message", func(args ...interface{}) {
		handleMessageChat(io, client, args...)
	})

	// Evento: Adivinhação de resposta
	client.On("chat:answer:guess", func(args ...interface{}) {
		handleGuessAnswerChat(io, client, args...)
	})

	// Evento: Iniciar turnos
	client.On("game:turns:start", func(args ...interface{}) {
		handleGameTurnsStart(io, client, args...)
	})

	// Evento: Desconexão
	client.On("disconnect", func(...any) {
		handleParticipantDisconnect(io, client)
	})

	// Evento: Solicitar ranking
	client.On("game:ranking", func(args ...interface{}) {
		handleGameRanking(io, client, args...)
	})

	// fmt.Printf("Client connected: %s", string(client.Id()))

	// client.On("disconnect", func(...any) {
	// 	fmt.Printf("Client disconnected: %s", string(client.Id()))
	// })

	// client.On("error", func(data any) {
	// 	log.Errorf("Error: %v", data)
	// })
	//////
}

func handleCreateRoom(io *socket.Server, client *socket.Socket, args ...interface{}) {
	// Verifica se o argumento é um mapa
	if len(args) > 0 {
		if data, ok := args[0].(map[string]interface{}); ok {
			roomName, _ := data["roomName"].(string)
			createRoom(io, client, roomName)
		}
	}
}

func handleJoinRoom(io *socket.Server, client *socket.Socket, args ...interface{}) {
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

			emitJoinMessage(io, roomName, userId, username)

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

				emitJoinMessage(io, roomName, userId, username)

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
}

func handleLeaveRoom(io *socket.Server, client *socket.Socket, args ...interface{}) {
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
}

func handleStartStrokeDrawing(io *socket.Server, client *socket.Socket, args ...interface{}) {
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
}

func handleLastPointsStrokeDrawing(io *socket.Server, client *socket.Socket, args ...interface{}) {
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
}

func handleClearDrawing(io *socket.Server, client *socket.Socket, args ...interface{}) {
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
}

func handleUndoDrawing(io *socket.Server, client *socket.Socket, args ...interface{}) {
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
}

func handleRedoDrawing(io *socket.Server, client *socket.Socket, args ...interface{}) {
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
}

func handleMessageChat(io *socket.Server, client *socket.Socket, args ...interface{}) {
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
}

func handleGuessAnswerChat(io *socket.Server, client *socket.Socket, args ...interface{}) {
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
}

func handleGameTurnsStart(io *socket.Server, client *socket.Socket, args ...interface{}) {
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
}

func handleParticipantDisconnect(io *socket.Server, client *socket.Socket) {
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
}

func handleGameRanking(io *socket.Server, client *socket.Socket, args ...interface{}) {
	if len(args) > 0 {
		data, ok := args[0].(map[string]interface{})
		if !ok {
			emitError(client, "Invalid data format", Nothing)
			return
		}

		roomName, _ := data["roomName"].(string)
		emitRanking(io, roomName)
	}
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
