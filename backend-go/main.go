package main

import (
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/zishang520/engine.io/v2/log"
	"github.com/zishang520/engine.io/v2/types"
	"github.com/zishang520/socket.io/v2/socket"
)

func main() {
	log.DEBUG = true
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
	go http.ListenAndServe(":3000", nil)

	io.On("connection", func(clients ...any) {
		client := clients[0].(*socket.Socket)

		// Evento "event" para receber e retransmitir mensagens
		client.On("event", func(datas ...any) {
			if len(datas) > 0 {
				// Retransmitir para todos os outros clientes
				client.Broadcast().Emit("event", datas[0])
			}
		})

		// Evento de desconexão
		client.On("disconnect", func(...any) {
			// Opcional: Lidar com desconexões, se necessário
		})
	})

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
