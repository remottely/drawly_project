package main

import (
	"fmt"
	"time"

	"github.com/zishang520/socket.io/v2/socket"
)

var wordsList = []string{
	"r",
	// "gato", "cachorro", "casa", "carro", "árvore", "flor", "sol", "lua",
	// "livro", "avião", "rio", "montanha", "praia", "peixe", "pássaro",
	// "computador", "telefone", "cadeira", "mesa", "namorados", "corda",
	// "futebol", "bola", "cama", "travesseiro", "cobertor", "chave", "porta",
}

func chooseRandomWord() string {
	if len(wordsList) == 0 {
		return "Nenhuma palavra disponível."
	}
	randomIndex := time.Now().UnixNano() % int64(len(wordsList))
	return wordsList[randomIndex]
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
