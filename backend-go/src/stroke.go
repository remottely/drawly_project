package main

import "fmt"

type StrokeType string

const (
	normal  StrokeType = "normal"
	eraser  StrokeType = "eraser"
	line    StrokeType = "line"
	polygon StrokeType = "polygon"
	square  StrokeType = "square"
	circle  StrokeType = "circle"
	bucket  StrokeType = "bucket"
)

type Stroke struct {
	Points     []Offset   `json:"points"`
	Color      uint32     `json:"color"`
	Size       float32    `json:"size"`
	Opacity    uint8      `json:"opacity"`
	StrokeType StrokeType `json:"strokeType"`
	Filled     *bool      `json:"filled"`
}

func ParseStrokeType(value string) (StrokeType, error) {
	switch StrokeType(value) {
	case normal, eraser, line, polygon, square, circle, bucket:
		return StrokeType(value), nil
	default:
		return "", fmt.Errorf("invalid stroke type: %s", value)
	}
}

func parseStroke(data map[string]any) (Stroke, error) {
	// Validar e extrair os pontos
	rawPoints, ok := data["points"].([]any)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'points'")
	}

	points := make([]Offset, len(rawPoints))
	for i, rawPoint := range rawPoints {
		pointMap, ok := rawPoint.(map[string]any)
		if !ok {
			return Stroke{}, fmt.Errorf("invalid point format at index %d", i)
		}

		dx, dxOk := pointMap["dx"].(float64)
		dy, dyOk := pointMap["dy"].(float64)

		if !dxOk || !dyOk {
			return Stroke{}, fmt.Errorf("missing or invalid 'dx' or 'dy' at index %d", i)
		}

		points[i] = Offset{Dx: dx, Dy: dy}
	}

	// Validar e extrair outras propriedades
	colorFloat64, ok := data["color"].(float64)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'color'")
	}
	// if colorFloat < 0 || colorFloat > 4294967295 {
	// 	return Stroke{}, fmt.Errorf("'color' value out of range for uint32")
	// }
	// color := uint32(colorFloat)

	sizeFloat64, ok := data["size"].(float64)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'size'")
	}

	opacityFloat64, ok := data["opacity"].(float64)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'opacity'")
	}

	rawType, ok := data["strokeType"].(string)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'strokeType'")
	}
	strokeType, err := ParseStrokeType(rawType)
	if err != nil {
		return Stroke{}, err
	}

	// Campo 'Filled' opcional
	var filled *bool
	if rawFilled, exists := data["filled"]; exists {
		if filledValue, ok := rawFilled.(bool); ok {
			filled = &filledValue
		} else {
			return Stroke{}, fmt.Errorf("invalid 'filled' value")
		}
	}

	// Retorna o objeto Stroke
	return Stroke{
		Points:     points,
		Color:      uint32(colorFloat64),
		Size:       float32(sizeFloat64),
		Opacity:    uint8(opacityFloat64),
		StrokeType: strokeType,
		Filled:     filled,
	}, nil
}
