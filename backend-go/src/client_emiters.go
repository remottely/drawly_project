package main

import "github.com/zishang520/socket.io/v2/socket"

func emitClientError(client *socket.Socket, message string, action ErrorActionType) {
	client.Emit(EventError, ErrorDTO{
		Message: message,
		Action:  action,
	})
}
