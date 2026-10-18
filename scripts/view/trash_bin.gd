extends Control

signal dumped
signal cup_trashed(token: String)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			dumped.emit()
			accept_event()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		dumped.emit()
		accept_event()


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_STRING and str(data).begins_with("cup:")


func _drop_data(_at: Vector2, data: Variant) -> void:
	cup_trashed.emit(str(data))


func _draw() -> void:
	var body := Rect2(size.x * 0.18, size.y * 0.28, size.x * 0.64, size.y * 0.62)
	draw_rect(body, Color("546E7A"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(body.position.x, body.position.y),
		Vector2(body.end.x, body.position.y),
		Vector2(body.end.x - 10, body.end.y),
		Vector2(body.position.x + 10, body.end.y),
	]), Color("455A64"))
	draw_rect(Rect2(size.x * 0.1, size.y * 0.18, size.x * 0.8, size.y * 0.12), Color("37474F"))
	draw_rect(Rect2(size.x * 0.38, size.y * 0.08, size.x * 0.24, size.y * 0.1), Color("78909C"))
	draw_line(Vector2(size.x * 0.32, size.y * 0.48), Vector2(size.x * 0.68, size.y * 0.72), Color("CFD8DC"), 3.0)
	draw_line(Vector2(size.x * 0.68, size.y * 0.48), Vector2(size.x * 0.32, size.y * 0.72), Color("CFD8DC"), 3.0)
