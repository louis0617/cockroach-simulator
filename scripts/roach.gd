extends Area2D

signal squished(roach: Node2D, golden: bool, pos: Vector2)

var golden := false
var alive := true
var _dir := Vector2.RIGHT
var _speed := 28.0
var _bounds := Rect2()
var _wiggle := 0.0
var _peek := 0.0


func setup(area: Rect2, is_golden: bool) -> void:
	_bounds = area
	golden = is_golden
	_dir = Vector2.from_angle(randf() * TAU)
	_speed = randf_range(18.0, 36.0)
	if golden:
		_speed *= 1.25
		modulate = Color("FFD54F")
	scale = Vector2.ONE * randf_range(0.78, 1.05)
	z_index = 2
	$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = 18.0
	_apply_xray()


func is_exposed() -> bool:
	return GameState.xray or _peek > 0.0


func _apply_xray() -> void:
	if GameState.xray:
		$Pulse.visible = true
		z_index = 6
	else:
		$Pulse.visible = false
		z_index = 2


func _process(delta: float) -> void:
	if not alive:
		return
	_wiggle += delta * 16.0
	_peek -= delta
	if _peek <= 0.0 and randf() < delta * 0.25:
		_peek = randf_range(0.35, 0.7)
	rotation = _dir.angle() + sin(_wiggle) * 0.22
	global_position += _dir * _speed * delta
	if not _bounds.has_point(global_position):
		global_position = global_position.clamp(_bounds.position, _bounds.position + _bounds.size)
		_dir = Vector2.from_angle(randf() * TAU)
	if randf() < delta * 0.5:
		_dir = _dir.rotated(randf_range(-1.1, 1.1)).normalized()
	if GameState.xray:
		z_index = 6
		$Pulse.visible = true
		$Pulse.modulate.a = 0.5 + sin(Time.get_ticks_msec() * 0.012) * 0.35
	elif _peek > 0.0:
		z_index = 5
		modulate.a = 0.85
	else:
		z_index = 2
		modulate.a = 1.0
	queue_redraw()


func smash() -> void:
	if not alive:
		return
	alive = false
	z_index = 7
	squished.emit(self, golden, global_position)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.85, 0.18), 0.08)
	tw.tween_property(self, "modulate:a", 0.0, 0.16).set_delay(0.04)
	tw.chain().tween_callback(queue_free)


func _draw() -> void:
	var body := Color("4E342E") if not golden else Color("6D4C41")
	var dark := Color("3E2723")
	draw_circle(Vector2(16, 0), 9.0, dark)
	draw_circle(Vector2(0, 0), 14.0, body)
	draw_circle(Vector2(-12, 0), 10.0, body.darkened(0.08))
	for i in 3:
		var y := -9.0 + i * 9.0
		draw_line(Vector2(-3, y * 0.15), Vector2(-22, y), dark, 2.0)
		draw_line(Vector2(-3, y * 0.15), Vector2(18, y * 0.65), dark, 2.0)
	draw_line(Vector2(22, -2), Vector2(34, -14), dark, 1.5)
	draw_line(Vector2(22, 2), Vector2(34, 14), dark, 1.5)
	if golden:
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 24, Color("FFEE58"), 2.2)
