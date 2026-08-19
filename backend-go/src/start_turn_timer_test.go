package main

import (
	"testing"

	"github.com/zishang520/socket.io/v2/socket"
)

// TestStartTurnTimerInitializesState verifies that calling startTurnTimer
// sets up the timer, increments turn count and chooses a word.
func TestStartTurnTimerInitializesState(t *testing.T) {
	rooms = map[string]*Room{}
	roomDrawings = map[string]*Drawing{}

	wordsList = []string{"apple"}

	r := newRoom("room")
	p := &Participant{UserId: "u1", Username: "one", IsConnected: true}
	r.addParticipant(p)
	r.CurrentDrawerTurnIndex = 0
	r.IsGameStarted = true
	rooms["room"] = r
	roomDrawings["room"] = &Drawing{}

	io := &socket.Server{}
	startTurnTimer(io, "room", 1)

	if r.ActiveTimer == nil {
		t.Fatalf("expected active timer")
	}
	if r.TurnCount == 0 {
		t.Fatalf("turn count should increment")
	}
	if r.CurrentWord == "" {
		t.Fatalf("word should be chosen")
	}

	r.ActiveTimer.Stop()
}
