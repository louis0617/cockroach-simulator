extends Control

signal picked(order_id: String)
signal cup_dropped(cup_order_id: String)

var order_id: String = ""
var platform: String = "self"
var ingredients: Array[String] = []
var tea_name: String = ""
var order_status: String = "pending"
var seconds_left: int = 0
var shout_id: String = ""
var patience: float = 1.0
var is_thief: bool = false
var disguise: int = 0
var _recipe_label: Label


func setup(order: Order) -> void:
	order_id = order.order_id
	platform = order.platform
	ingredients = order.ingredients.duplicate()
	tea_name = order.display_name
	order_status = order.status
	seconds_left = maxi(int(ceil(order.time_left)), 0)
	shout_id = order.order_id
	is_thief = false
	if order.time_limit > 0.0:
		patience = clampf(order.time_left / order.time_limit, 0.0, 1.0)
	disguise = 0
	_show_recipe(order.describe())
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()


func setup_thief(fake_id: String, patience_ratio: float, disguise_level: int, look_platform: String, look_items: Array) -> void:
	is_thief = true
	disguise = disguise_level
	order_id = ""
	shout_id = fake_id
	platform = look_platform if disguise_level >= 2 else "self"
	ingredients.clear()
	if disguise_level >= 2:
		for item in look_items:
			ingredients.append(str(item))
	order_status = "ready"
	patience = patience_ratio
	seconds_left = int(ceil(patience_ratio * 10.0))
	_show_recipe("、".join(ingredients))
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_STRING or not str(data).begins_with("cup:"):
		return false
	if is_thief:
		return true
	return order_status == "pending" or order_status == "making" or order_status == "ready" or order_status == "handover_pending"


func _drop_data(_at: Vector2, data: Variant) -> void:
	cup_dropped.emit(str(data))


func _show_recipe(text: String) -> void:
	if _recipe_label == null:
		_recipe_label = Label.new()
		_recipe_label.position = Vector2(10, 32)
		_recipe_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_recipe_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_recipe_label.add_theme_font_size_override("font_size", 15)
		_recipe_label.add_theme_color_override("font_color", Color("4E342E"))
		add_child(_recipe_label)
		if not resized.is_connected(_fit_recipe):
			resized.connect(_fit_recipe)
	_recipe_label.text = text
	_fit_recipe()


func _fit_recipe() -> void:
	if _recipe_label == null:
		return
	_recipe_label.size = Vector2(maxf(size.x - 20.0, 40.0), 62.0)


func _gui_input(event: InputEvent) -> void:
	if is_thief:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			picked.emit(order_id)
			accept_event()


func _draw() -> void:
	var cx := size.x * 0.5
	var obvious := is_thief and disguise <= 0
	var bubble := Color("FFCDD2") if obvious else Color("FFFcf7")
	draw_rect(Rect2(6, 4, size.x - 12, 96), bubble, true)
	draw_rect(Rect2(6, 4, size.x - 12, 96), Color("8D6E63"), false, 2.0)
	var id_color := Color("B71C1C") if is_thief and disguise <= 1 else Color("3E2723")
	draw_string(ThemeDB.fallback_font, Vector2(10, 26), shout_id, HORIZONTAL_ALIGNMENT_LEFT, size.x - 64, 16, id_color)
	var bar_w := (size.x - 24.0) * clampf(patience, 0.0, 1.0)
	draw_rect(Rect2(12, 104, size.x - 24, 8), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(12, 104, bar_w, 8), Color("2E7D32").lerp(Color("C62828"), 1.0 - clampf(patience, 0.0, 1.0)))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 52, 28), "%ds" % seconds_left, HORIZONTAL_ALIGNMENT_RIGHT, 42, 16, Color("5D4037"))
	draw_circle(Vector2(cx, 158), 22.0, Color(0, 0, 0, 0.15))
	var shirt := Color("FFD54F")
	if is_thief and disguise <= 1:
		shirt = Color("6D4C41")
	elif platform == "ebu":
		shirt = Color("64B5F6")
	elif platform == "self":
		shirt = Color("81C784")
	draw_rect(Rect2(cx - 24, 126, 48, 46), shirt)
	draw_circle(Vector2(cx, 116), 20.0, Color("FFCC80"))
	draw_circle(Vector2(cx - 7, 114), 2.2, Color("3E2723"))
	draw_circle(Vector2(cx + 7, 114), 2.2, Color("3E2723"))
	if is_thief and disguise <= 2:
		draw_line(Vector2(cx - 12, 108), Vector2(cx - 4, 112), Color("3E2723"), 2.0)
		draw_line(Vector2(cx + 12, 108), Vector2(cx + 4, 112), Color("3E2723"), 2.0)
	if is_thief and disguise <= 0:
		draw_arc(Vector2(cx, 158), 34.0, 0, TAU, 24, Color("C62828"), 3.0)
	elif not is_thief and order_status == "making":
		draw_arc(Vector2(cx, 158), 34.0, 0, TAU, 24, Color("E65100"), 3.0)
	elif not is_thief and (order_status == "ready" or order_status == "handover_pending"):
		draw_arc(Vector2(cx, 158), 34.0, 0, TAU, 24, Color("2E7D32"), 3.0)


func _draw_cup(at: Vector2) -> void:
	var col := Color("EFEBE9")
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-10, -16), at + Vector2(10, -16),
		at + Vector2(8, 16), at + Vector2(-8, 16),
	]), col)
	draw_line(at + Vector2(10, -6), at + Vector2(18, 2), Color("BCAAA4"), 2.0)
