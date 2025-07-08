package main

import (
	"testing"
	"time"

	"github.com/zishang520/socket.io/v2/socket"
)

// TestHandleParticipantDisconnect verifies that the participant is marked
// disconnected and removed from room after the timeout.
func TestHandleParticipantDisconnect(t *testing.T) {
	rooms = map[string]*Room{}
	roomDrawings = map[string]*Drawing{}
	roomUsers = map[string]*RoomUser{}

	r := newRoom("room")
	p := &Participant{UserId: "u1", Username: "one", IsConnected: true}
	r.addParticipant(p)
	r.CurrentDrawerTurnIndex = 0
	rooms["room"] = r
	roomDrawings["room"] = &Drawing{}

	client := &socket.Socket{id: []byte("c1")}
	roomUsers["c1"] = &RoomUser{RoomName: "room", UserId: p.UserId, Username: p.Username}

	handleParticipantDisconnect(&socket.Server{}, client)

	if _, ok := roomUsers["c1"]; ok {
		t.Fatalf("room user should be deleted")
	}
	if p.IsConnected {
		t.Fatalf("participant should be marked disconnected")
	}

	time.Sleep(6 * time.Second)
	if _, ok := r.Participants[p.UserId]; ok {
		t.Fatalf("participant should be removed from room")
	}
	if _, ok := rooms["room"]; ok {
		t.Fatalf("room should be deleted when empty")
	}
}
