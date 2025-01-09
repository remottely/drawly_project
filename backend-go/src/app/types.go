package app

type Offset struct {
	Dx float64 `json:"dx"`
	Dy float64 `json:"dy"`
}

type Stroke struct {
	Points     []Offset `json:"points"`
	Color      int      `json:"color"`
	Size       int      `json:"size"`
	Opacity    float64  `json:"opacity"`
	StrokeType string   `json:"strokeType"`
	Filled     *bool    `json:"filled"`
}

type Room struct {
	Name                             string
	Participants                     map[string]*Participant
	TurnQueue                        []*Participant
	CurrentDrawerTurnIndex           int
	CurrentWord                      string
	TurnCount                        int
	ParticipantsWhoAnsweredCorrectly map[string]bool
}

type Drawing struct {
	Strokes       []Stroke `json:"strokes"`
	BackupStrokes []Stroke `json:"backupStrokes"`
}

type Participant struct {
	UserId      string  `json:"userId"`
	Username    string  `json:"username"`
	UserAvatar  *string `json:"userAvatar"`
	IsLogged    bool    `json:"isLogged"`
	IsConnected bool    `json:"isConnected"`
	Score       int     `json:"score"`
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
	Turn                  int    `json:"turn"`                  // Número do turno atual
	TotalDuration         int    `json:"totalDuration"`         // Duração total do turno em milissegundos
	CurrentDrawerUserId   string `json:"currentDrawerUserId"`   // ID do usuário que está desenhando
	CurrentDrawerUsername string `json:"currentDrawerUsername"` // Nome do usuário que está desenhando
}

type ErrorDTO struct {
	Message string `json:"message"` // Mensagem de erro
	Action  string `json:"action"`  // Ação sugerida (e.g., "nothing", "nothing")
}
