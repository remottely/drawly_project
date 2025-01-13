package main

import (
	"fmt"

	"github.com/zishang520/socket.io/v2/socket"
)

func cancelActiveTimer(room *Room) {
	if room.ActiveTimer != nil {
		room.ActiveTimer.Stop()
		room.ActiveTimer = nil
	}
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
