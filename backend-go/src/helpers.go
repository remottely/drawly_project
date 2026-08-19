package main

import (
	"github.com/labstack/gommon/log"
	"github.com/zishang520/socket.io/v2/socket"
)

// Requer stateMu.
func cancelActiveTimer(room *Room) {
	if room.ActiveTimer != nil {
		room.ActiveTimer.Stop()
		room.ActiveTimer = nil
	}
}

// Requer stateMu.
func validateCurrentDrawer(io *socket.Server, room *Room, roomName string) *Participant {
	currentDrawer := room.getCurrentDrawer()
	if currentDrawer == nil {
		logInfo("Não há participantes conectados na sala %s.", roomName)
		emitRoomError(io, roomName, "Nenhum participante conectado para ser o desenhista.", Dialog)
		return nil
	}
	return currentDrawer
}

func logInfo(message string, args ...interface{}) {
	log.Printf("[INFO] "+message+"\n", args...)
}

func logError(message string, args ...interface{}) {
	log.Errorf("[ERROR] "+message+"\n", args...)
}
