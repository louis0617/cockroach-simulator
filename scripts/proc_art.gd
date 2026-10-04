class_name ProcArt
extends RefCounted

const CANDY_COLORS: Array[Color] = [
	Color("E53935"),
	Color("FB8C00"),
	Color("FDD835"),
	Color("43A047"),
	Color("1E88E5"),
	Color("8E24AA"),
	Color("EC407A"),
	Color("26C6DA"),
]


static func candy_texture(color: Color, size: int = 96) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size * 0.5, size * 0.48)
	var r := size * 0.38
	_fill_ellipse(img, Vector2(c.x + 2, c.y + 6), r * 1.02, r * 0.92, Color(0, 0, 0, 0.22))
	_fill_circle(img, c, r, color.darkened(0.12))
	_fill_circle(img, c, r * 0.92, color)
	_fill_ellipse(img, c + Vector2(-r * 0.28, -r * 0.32), r * 0.38, r * 0.22, Color(1, 1, 1, 0.55))
	_fill_ellipse(img, c + Vector2(r * 0.18, r * 0.22), r * 0.22, r * 0.12, color.lightened(0.25))
	return ImageTexture.create_from_image(img)


static func slipper_texture(size: int = 220) -> ImageTexture:
	var img := Image.create(size, int(size * 1.15), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var sole := Color("F48FB1")
	var sole_dark := Color("EC407A")
	var strap := Color("F8BBD0")
	var cx := size * 0.5
	var cy := size * 0.58
	_fill_ellipse(img, Vector2(cx + 4, cy + 8), size * 0.34, size * 0.46, Color(0, 0, 0, 0.2))
	_fill_ellipse(img, Vector2(cx, cy), size * 0.33, size * 0.45, sole_dark)
	_fill_ellipse(img, Vector2(cx, cy - 4), size * 0.30, size * 0.42, sole)
	_fill_ellipse(img, Vector2(cx - 18, cy - 28), size * 0.12, size * 0.08, Color(1, 1, 1, 0.35))
	# Y strap
	_fill_ellipse(img, Vector2(cx, cy - 10), size * 0.08, size * 0.22, strap)
	_fill_ellipse(img, Vector2(cx - 28, cy + 8), size * 0.16, size * 0.07, strap)
	_fill_ellipse(img, Vector2(cx + 28, cy + 8), size * 0.16, size * 0.07, strap)
	return ImageTexture.create_from_image(img)


static func _fill_circle(img: Image, center: Vector2, radius: float, color: Color) -> void:
	_fill_ellipse(img, center, radius, radius, color)


static func _fill_ellipse(img: Image, center: Vector2, rx: float, ry: float, color: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var x0 := maxi(int(center.x - rx - 1), 0)
	var y0 := maxi(int(center.y - ry - 1), 0)
	var x1 := mini(int(center.x + rx + 1), w - 1)
	var y1 := mini(int(center.y + ry + 1), h - 1)
	var rx2 := rx * rx
	var ry2 := ry * ry
	if rx2 <= 0.0 or ry2 <= 0.0:
		return
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx := (x + 0.5 - center.x)
			var dy := (y + 0.5 - center.y)
			if (dx * dx) / rx2 + (dy * dy) / ry2 <= 1.0:
				img.set_pixel(x, y, color)
