package main

import (
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/zishang520/engine.io/v2/log"
	"github.com/zishang520/engine.io/v2/types"
	"github.com/zishang520/socket.io/v2/socket"
)

const (
	Version = "0.51.1"
)

func main() {
	log.DEBUG = true
	io := setupServer()
	io.On("connection", func(clients ...any) {
		client := clients[0].(*socket.Socket)
		fmt.Printf("Client connected: %s", string(client.Id()))

		handleConnection(io, client)
	})
	handleGracefulShutdown(io)
}

func setupServer() *socket.Server {
	c := socket.DefaultServerOptions()
	c.SetServeClient(true)
	c.SetConnectionStateRecovery(&socket.ConnectionStateRecovery{})
	// c.SetAllowEIO3(true)
	c.SetPingInterval(300 * time.Millisecond)
	c.SetPingTimeout(200 * time.Millisecond)
	c.SetMaxHttpBufferSize(1000000)
	c.SetConnectTimeout(1000 * time.Millisecond)
	c.SetCors(&types.Cors{
		Origin:      "http://localhost:8081 http://localhost:8082 http://localhost:8083 http://localhost:8084 http://localhost:8085 http://localhost:8086 http://localhost:8087 http://localhost:8088",
		Credentials: true,
		Headers:     []string{"Content-Type", "Authorization"},
	})
	io := socket.NewServer(nil, nil)
	http.Handle("/socket.io/", io.ServeHandler(nil))
	go http.ListenAndServe(":5555", nil)
	return io
}

func handleGracefulShutdown(io *socket.Server) {
	exit := make(chan struct{})
	SignalC := make(chan os.Signal)

	signal.Notify(SignalC, os.Interrupt, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)

	go func() {
		for s := range SignalC {
			switch s {
			case os.Interrupt, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT:
				close(exit)
				return
			}
		}
	}()

	<-exit
	io.Close(nil)
	os.Exit(0)
}
