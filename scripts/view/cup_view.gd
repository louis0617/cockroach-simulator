extends Control

var layers: Array[String] = []
var sealed: bool = false


func show_layers(items: Array, is_sealed: bool) -> void:
	layers.clear()
	for item in items:
		layers.append(str(item))
	sealed = is_sealed
	queue_redraw()


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
	for item in layers:
		draw_rect(Rect2(c.x - 18, y - 14, 36, 16), ShopColors.of(item))
		y -= 16.0
	if sealed:
		draw_rect(Rect2(c.x - 30, c.y - 48, 60, 10), Color("FF8A65"))
