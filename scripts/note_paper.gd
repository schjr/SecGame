class_name NotePaper
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var paper_rect := Rect2(Vector2.ZERO, size)
	draw_rect(paper_rect, Color("#fff4c9"))

	var line_color := Color(0.36, 0.56, 0.72, 0.25)
	var first_line := 76.0
	var line_spacing := 36.0
	var y := first_line
	while y < size.y - 18.0:
		draw_line(Vector2(18, y), Vector2(size.x - 18, y), line_color, 1.0)
		y += line_spacing

	draw_line(
		Vector2(58, 18),
		Vector2(58, size.y - 18),
		Color(0.75, 0.24, 0.24, 0.28),
		1.5
	)

	var fold_size := 34.0
	var fold := PackedVector2Array([
		Vector2(size.x - fold_size, 0),
		Vector2(size.x, 0),
		Vector2(size.x, fold_size)
	])
	draw_colored_polygon(fold, Color("#e8d79b"))
	draw_line(
		Vector2(size.x - fold_size, 0),
		Vector2(size.x, fold_size),
		Color(0.35, 0.28, 0.16, 0.22),
		1.0
	)
