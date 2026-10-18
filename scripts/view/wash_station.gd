extends Control

signal used

var kind: String = "sink"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			used.emit()
			accept_event()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		used.emit()
		accept_event()


func _draw() -> void:
	if kind == "rinse":
		_draw_rinse()
	else:
		_draw_sink()


func _draw_sink() -> void:
	var basin := Rect2(size.x * 0.08, size.y * 0.42, size.x * 0.84, size.y * 0.48)
	draw_rect(basin, Color("90A4AE"))
	draw_rect(Rect2(basin.position.x + 8, basin.position.y + 8, basin.size.x - 16, basin.size.y - 16), Color("4FC3F7"))
	draw_rect(Rect2(size.x * 0.42, size.y * 0.08, size.x * 0.16, size.y * 0.38), Color("78909C"))
	draw_rect(Rect2(size.x * 0.28, size.y * 0.2, size.x * 0.44, size.y * 0.1), Color("607D8B"))
	draw_line(Vector2(size.x * 0.5, size.y * 0.3), Vector2(size.x * 0.5, basin.position.y + 18), Color("E1F5FE"), 4.0)


func _draw_rinse() -> void:
	var basin := Rect2(size.x * 0.1, size.y * 0.55, size.x * 0.8, size.y * 0.36)
	draw_rect(basin, Color("80CBC4"))
	draw_rect(Rect2(basin.position.x + 8, basin.position.y + 6, basin.size.x - 16, basin.size.y - 12), Color("B2EBF2"))
	var cup := Rect2(size.x * 0.34, size.y * 0.28, size.x * 0.32, size.y * 0.4)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cup.position.x, cup.position.y),
		Vector2(cup.end.x, cup.position.y),
		Vector2(cup.end.x - 6, cup.end.y),
		Vector2(cup.position.x + 6, cup.end.y),
	]), Color("ECEFF1"))
	draw_rect(Rect2(size.x * 0.46, size.y * 0.06, size.x * 0.08, size.y * 0.24), Color("78909C"))
	draw_line(Vector2(size.x * 0.5, size.y * 0.28), Vector2(size.x * 0.5, cup.position.y + 16), Color("E1F5FE"), 3.0)
