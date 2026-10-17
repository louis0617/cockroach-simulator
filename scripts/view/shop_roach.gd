extends Node2D

signal smashed

var alive: bool = true
var bounds: Rect2 = Rect2()
var spoil: float = 0.0
var goal: Vector2 = Vector2.ZERO
var has_goal: bool = false
var speed: float = 78.0
var _goal_time: float = 0.0


func set_goal(point: Vector2) -> void:
	goal = point
	has_goal = true
	_goal_time = 0.0


func _process(delta: float) -> void:
	if not alive:
		return
	_goal_time += delta
	if has_goal:
		var to := goal - position
		if to.length() > 10.0:
			position += to.normalized() * speed * delta
		else:
			position += Vector2.from_angle(_goal_time * 9.0) * 10.0 * delta
	var min_p := bounds.position + Vector2(12, 12)
	var max_p := bounds.position + bounds.size - Vector2(12, 12)
	if max_p.x > min_p.x and max_p.y > min_p.y:
		position = position.clamp(min_p, max_p)
	queue_redraw()


func contains(point: Vector2) -> bool:
	return alive and position.distance_to(point) < 30.0


func smash() -> void:
	if not alive:
		return
	alive = false
	smashed.emit()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.4, 0.25), 0.08)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var body := Color("4E342E")
	draw_circle(Vector2(10, 0), 7.0, Color("3E2723"))
	draw_circle(Vector2.ZERO, 11.0, body)
	draw_circle(Vector2(-10, 0), 8.0, body)
	draw_line(Vector2(-2, -4), Vector2(-16, -12), Color("3E2723"), 2.0)
	draw_line(Vector2(-2, 4), Vector2(-16, 12), Color("3E2723"), 2.0)
	draw_line(Vector2(8, -3), Vector2(20, -10), Color("3E2723"), 1.5)
	draw_line(Vector2(8, 3), Vector2(20, 10), Color("3E2723"), 1.5)
