package main

type Drawing struct {
	Strokes       []Stroke `json:"strokes"`
	BackupStrokes []Stroke `json:"backupStrokes"`
}

func (d *Drawing) addStroke(stroke Stroke) {
	d.Strokes = append(d.Strokes, stroke)
}

func (d *Drawing) addStrokeLastPoints(points []Offset) {
	if len(d.Strokes) > 0 {
		lastStroke := &d.Strokes[len(d.Strokes)-1]
		lastStroke.Points = append(lastStroke.Points, points...)
	}
}

func (d *Drawing) clear() {
	d.Strokes = nil
	d.BackupStrokes = nil
}

func (d *Drawing) undo() *Stroke {
	if len(d.Strokes) == 0 {
		return nil
	}
	lastStroke := d.Strokes[len(d.Strokes)-1]
	d.Strokes = d.Strokes[:len(d.Strokes)-1]
	d.BackupStrokes = append(d.BackupStrokes, lastStroke)
	return &lastStroke
}

func (d *Drawing) redo() *Stroke {
	if len(d.BackupStrokes) == 0 {
		return nil
	}
	lastBackup := d.BackupStrokes[len(d.BackupStrokes)-1]
	d.BackupStrokes = d.BackupStrokes[:len(d.BackupStrokes)-1]
	d.Strokes = append(d.Strokes, lastBackup)
	return &lastBackup
}
