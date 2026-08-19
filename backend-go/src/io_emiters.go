package main

import (
	"sort"

	"github.com/zishang520/socket.io/v2/socket"
)

func emitRoomList(io *socket.Server) {
	io.Emit(EventRoomAll, map[string]any{
		"allRooms": getRoomNames(),
	})
}

func emitDrawingState(io *socket.Server, roomName string, drawing *Drawing) {
	io.To(socket.Room(roomName)).Emit(EventDrawingStrokeAll, map[string]interface{}{
		"strokes": drawing.Strokes,
	})
}

func emitJoinMessage(io *socket.Server, roomName, userId, username string) {
	icon := "info"
	message := Message{
		Icon:     &icon,
		UserId:   userId,
		Username: username,
		Text:     "entrou",
	}
	io.To(socket.Room(roomName)).Emit(EventChatMessage, message)
}

func emitRoomError(io *socket.Server, roomName string, message string, action ErrorActionType) {
	io.To(socket.Room(roomName)).Emit(EventError, ErrorDTO{
		Message: message,
		Action:  action,
	})
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
	sort.Slice(ranking, func(i, j int) bool {
		return ranking[i]["score"].(uint16) > ranking[j]["score"].(uint16)
	})

	io.To(socket.Room(roomName)).Emit(EventGameRanking, map[string]any{
		"ranking": ranking,
	})
}
