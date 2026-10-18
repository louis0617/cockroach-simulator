extends Control

var order_id: String = ""
var caption: String = ""
var _items: Array = []


func setup(id: String, items: Array) -> void:
	order_id = id
	_items = items.duplicate()
	custom_minimum_size = Vector2(96, 130)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cup := preload("res://scripts/view/cup_view.gd").new()
	cup.position = Vector2(8, 0)
	cup.size = Vector2(80, 96)
	cup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cup.show_layers(items, true)
	add_child(cup)
	var lab := Label.new()
	lab.text = id
	lab.position = Vector2(0, 98)
	lab.size = Vector2(96, 24)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 14)
	lab.add_theme_color_override("font_color", Color("3E2723"))
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lab)


func set_caption(text: String) -> void:
	caption = text
	if get_child_count() < 2:
		return
	var lab := get_child(1) as Label
	if lab != null:
		lab.text = text


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		accept_event()


func _get_drag_data(_at: Vector2) -> Variant:
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(80, 110)
	preview.size = Vector2(80, 110)
	var cup := preload("res://scripts/view/cup_view.gd").new()
	cup.size = Vector2(80, 96)
	cup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cup.show_layers(_items, true)
	preview.add_child(cup)
	var lab := Label.new()
	lab.text = caption if caption != "" else order_id
	lab.position = Vector2(0, 90)
	lab.size = Vector2(80, 20)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(lab)
	set_drag_preview(preview)
	return order_id
