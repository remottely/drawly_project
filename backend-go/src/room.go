package main

import (
	"fmt"
	"sort"
	"time"
)

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
