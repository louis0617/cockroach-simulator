extends Button

var ingredient_id: String = ""
var dirt: int = 0
var stock: int = -1
var track_stock: bool = false


func setup(item: String) -> void:
	ingredient_id = item
	text = ""
	flat = true
	custom_minimum_size = Vector2(160, 108)


func set_supply(layers: int, portions: int, track: bool) -> void:
	dirt = layers
	stock = portions
	track_stock = track
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, 36.0)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-62, 8), center + Vector2(62, 8),
		center + Vector2(48, 36), center + Vector2(-48, 36),
	]), Color("ECEFF1"))
	var fill := ShopColors.of(ingredient_id)
	draw_circle(center, 24.0, fill.darkened(0.35))
	draw_circle(center, 20.0, fill)
	draw_circle(center + Vector2(-7, -8), 6.0, Color(1, 1, 1, 0.55))
	for i in mini(dirt, 3):
		draw_circle(center + Vector2(-16.0 + float(i) * 16.0, 10.0), 5.0, Color("5D4037"))
	var font := ThemeDB.fallback_font
	if dirt >= 3:
		draw_string(font, Vector2(0, 22), "要洗", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color("4E342E"))
	elif track_stock and stock <= 0:
		draw_string(font, Vector2(0, 22), "补货", HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color("6D4C41"))
	elif track_stock:
		draw_string(font, Vector2(0, 22), "余%d" % stock, HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color("5D4037"))
	draw_string(font, Vector2(0, size.y - 8), ingredient_id, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color("3E2723"))
