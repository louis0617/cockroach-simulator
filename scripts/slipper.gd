extends Node2D

signal slammed(at: Vector2, radius: float)

var _slamming := false


func _ready() -> void:
	$Sprite2D.texture = ProcArt.slipper_texture()
	$Sprite2D.centered = true
	_apply_scale()
	visible = false
	GameState.upgrade_changed.connect(_apply_scale)


func _apply_scale() -> void:
	scale = Vector2.ONE * GameState.slipper_scale() * 0.85


func try_slam(at: Vector2) -> void:
	if _slamming:
		return
	_slamming = true
	visible = true
	modulate.a = 1.0
	var start := at + Vector2(-280, -360)
	var finish := at + Vector2(220, 130)
	global_position = start
	rotation = -1.15
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(self, "global_position", at + Vector2(-12, 8), 0.09)
	tw.parallel().tween_property(self, "rotation", 0.55, 0.09)
	tw.tween_callback(func() -> void:
		slammed.emit(at, GameState.slipper_radius())
	)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", finish, 0.11)
	tw.parallel().tween_property(self, "rotation", 1.55, 0.11)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.11)
	tw.tween_callback(func() -> void:
		visible = false
		modulate.a = 1.0
		_slamming = false
	)
