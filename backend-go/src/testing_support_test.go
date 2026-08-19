package main

import "time"

// veryLongDelay é usado quando um teste precisa de um timer que existe mas nunca
// dispara durante a execução.
const veryLongDelay = time.Hour

// resetGlobalState zera os três mapas globais do servidor.
//
// Enquanto o estado do jogo for global (achado R5/4.4), todo teste que os toca
// precisa limpá-los primeiro — senão a ordem de execução dos testes muda o
// resultado. Esta função existe para que essa limpeza seja feita em um lugar só;
// ela desaparece quando o RoomRegistry da fase 4 for introduzido.
func resetGlobalState() {
	rooms = make(map[string]*Room)
	roomDrawings = make(map[string]*Drawing)
	roomUsers = make(map[string]*RoomUser)
}

// participantWithScore monta um participante conectado com um score inicial.
func participantWithScore(userID string, score uint16) *Participant {
	return &Participant{
		UserId:      userID,
		Username:    "user-" + userID,
		IsConnected: true,
		Score:       score,
	}
}
