package socket

import (
	"net/http"
	"time"

	eit "github.com/zishang520/engine.io/v2/types"
)

type Room string

type BroadcastOperator struct{}

func (b *BroadcastOperator) Emit(event string, args ...interface{}) {}

type Server struct{}

type ServerOptions struct{}

type ConnectionStateRecovery struct{}

func DefaultServerOptions() *ServerOptions                                     { return &ServerOptions{} }
func (o *ServerOptions) SetServeClient(b bool)                                 {}
func (o *ServerOptions) SetConnectionStateRecovery(c *ConnectionStateRecovery) {}
func (o *ServerOptions) SetPingInterval(d time.Duration)                       {}
func (o *ServerOptions) SetPingTimeout(d time.Duration)                        {}
func (o *ServerOptions) SetMaxHttpBufferSize(i int)                            {}
func (o *ServerOptions) SetConnectTimeout(d time.Duration)                     {}
func (o *ServerOptions) SetCors(c *eit.Cors)                                   {}

func NewServer(a interface{}, b interface{}) *Server { return &Server{} }
func (s *Server) ServeHandler(v interface{}) http.Handler {
	return http.HandlerFunc(func(http.ResponseWriter, *http.Request) {})
}
func (s *Server) On(event string, f func(...interface{})) {}
func (s *Server) Emit(event string, args ...interface{})  {}
func (s *Server) To(room Room) *BroadcastOperator         { return &BroadcastOperator{} }
func (s *Server) Close(v interface{}) error               { return nil }

// Socket represents a client connection
type Socket struct{ id []byte }

func (s *Socket) Id() []byte                              { return s.id }
func (s *Socket) On(event string, f func(...interface{})) {}
func (s *Socket) Emit(event string, args ...interface{})  {}
func (s *Socket) Join(room Room)                          {}
func (s *Socket) Leave(room Room)                         {}
