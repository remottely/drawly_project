package main

type Offset struct {
	Dx float64 `json:"dx"`
	Dy float64 `json:"dy"`
}

type Participant struct {
	UserId        string  `json:"userId"`
	Username      string  `json:"username"`
	UserAvatar    *string `json:"userAvatar"`
	IsLogged      bool    `json:"isLogged"`
	IsConnected   bool    `json:"isConnected"`
	Score         uint16  `json:"score"`
	PreviousOrder uint8   `json:"-"`
}

type Message struct {
	Icon     *string `json:"icon"`     // Ícone opcional
	UserId   string  `json:"userId"`   // ID do usuário
	Username string  `json:"username"` // Nome do usuário
	Text     string  `json:"text"`     // Texto da mensagem
}

type Answer struct {
	Icon      *string `json:"icon"`      // Ícone opcional (pode ser nil)
	UserId    string  `json:"userId"`    // ID do usuário
	Username  string  `json:"username"`  // Nome do usuário
	Text      string  `json:"text"`      // Texto da resposta
	IsCorrect bool    `json:"isCorrect"` // Indica se a resposta está correta
}

type Turn struct {
	Word                  string `json:"word"`                  // Palavra que está sendo desenhada
	Turn                  uint8  `json:"turn"`                  // Número do turno atual
	TotalDuration         uint32 `json:"totalDuration"`         // Duração total do turno em milissegundos
	CurrentDrawerUserId   string `json:"currentDrawerUserId"`   // ID do usuário que está desenhando
	CurrentDrawerUsername string `json:"currentDrawerUsername"` // Nome do usuário que está desenhando
	IsGameStarted         bool   `json:"isGameStarted"`
}

type ErrorActionType string

const (
	Nothing ErrorActionType = "nothing"
	Retry   ErrorActionType = "retry"
	Ignore  ErrorActionType = "ignore"
	Log     ErrorActionType = "log"
	Pop     ErrorActionType = "pop"
	Dialog  ErrorActionType = "dialog"
)

// Validação do enum
func isValidErrorActionType(action ErrorActionType) bool {
	switch action {
	case Nothing, Retry, Ignore, Log, Pop, Dialog:
		return true
	default:
		return false
	}
}

type ErrorDTO struct {
	Message string          `json:"message"`
	Action  ErrorActionType `json:"action"`
}

type RoomUser struct {
	RoomName   string  `json:"roomName"`
	UserId     string  `json:"userId"`
	Username   string  `json:"username"`
	UserAvatar *string `json:"userAvatar"`
	IsLogged   bool    `json:"isLogged"`
}
