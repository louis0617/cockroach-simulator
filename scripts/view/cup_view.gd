extends Control

var layers: Array[String] = []
var sealed: bool = false
var water_ratio: float = 0.0

signal hold_changed(down: bool)

var _holding: bool = false


func show_layers(items: Array, is_sealed: bool) -> void:
	layers.clear()
	for item in items:
		layers.append(str(item))
	sealed = is_sealed
	queue_redraw()


func show_state(items: Array, water: float, is_sealed: bool) -> void:
	water_ratio = clampf(water, 0.0, 1.0)
	show_layers(items, is_sealed)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		_set_holding(mb.pressed)
		accept_event()
	elif event is InputEventScreenTouch:
		_set_holding((event as InputEventScreenTouch).pressed)
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_set_holding(false)


func _set_holding(down: bool) -> void:
	if _holding == down:
		return
	_holding = down
	hold_changed.emit(down)


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var c := size * 0.5
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-28, -40), c + Vector2(28, -40),
		c + Vector2(22, 48), c + Vector2(-22, 48),
	]), Color("F5F5F5"))
	draw_line(c + Vector2(28, -16), c + Vector2(46, 4), Color("B0BEC5"), 4.0)
	var y := c.y + 36.0
	if water_ratio > 0.0:
		var liquid_h := 70.0 * water_ratio
		draw_rect(Rect2(c.x - 18, c.y + 40.0 - liquid_h, 36, liquid_h), Color("C5E1A5"))
	for item in layers:
		draw_rect(Rect2(c.x - 18, y - 14, 36, 16), ShopColors.of(item))
		y -= 16.0
	if sealed:
		draw_rect(Rect2(c.x - 30, c.y - 48, 60, 10), Color("FF8A65"))
