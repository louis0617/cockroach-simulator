extends TextureRect

signal picked


func _ready() -> void:
	texture = ProcArt.slipper_texture(220)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			picked.emit()
			accept_event()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		picked.emit()
		accept_event()
