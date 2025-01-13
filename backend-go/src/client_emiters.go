package main

import "github.com/zishang520/socket.io/v2/socket"

func emitError(client *socket.Socket, message string, action ErrorActionType) {
	client.Emit("error", ErrorDTO{
		Message: message,
		Action:  action,
	})
}
