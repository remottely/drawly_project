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

type ColorJSON struct {
	A          float64 `json:"a"`          // valor entre 0.0 e 1.0
	R          float64 `json:"r"`          // valor entre 0.0 e 1.0
	G          float64 `json:"g"`          // valor entre 0.0 e 1.0
	B          float64 `json:"b"`          // valor entre 0.0 e 1.0
	ColorSpace string  `json:"colorSpace"` // opcional – por exemplo, "ColorSpace.sRGB"
}

type Stroke struct {
	Points     []Offset   `json:"points"`
	Color      ColorJSON  `json:"color"`
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
	// Processa os pontos:
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

	// Processa a cor:
	rawColor, ok := data["color"].(map[string]any)
	if !ok {
		return Stroke{}, fmt.Errorf("invalid or missing 'color'")
	}
	color := ColorJSON{
		A:          rawColor["a"].(float64),
		R:          rawColor["r"].(float64),
		G:          rawColor["g"].(float64),
		B:          rawColor["b"].(float64),
		ColorSpace: rawColor["colorSpace"].(string), // ou um valor default se não estiver presente
	}

	// Processa size e opacity:
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

	// Campo 'Filled' opcional:
	var filled *bool
	if rawFilled, exists := data["filled"]; exists {
		if filledValue, ok := rawFilled.(bool); ok {
			filled = &filledValue
		} else {
			return Stroke{}, fmt.Errorf("invalid 'filled' value")
		}
	}

	return Stroke{
		Points:     points,
		Color:      color,
		Size:       float32(sizeFloat64),
		Opacity:    uint8(opacityFloat64),
		StrokeType: strokeType,
		Filled:     filled,
	}, nil
}
