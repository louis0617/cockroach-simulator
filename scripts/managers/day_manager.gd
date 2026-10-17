extends Node

signal phase_changed(new_phase: String)
signal day_tick(time_left: float)

var phase: String = "prep"
var day_index: int = 1
var day_duration: float = 120.0
var clock_frozen: bool = false
var _elapsed: float = 0.0


func start_day(day: int, duration: float = -1.0) -> void:
	day_index = day
	_elapsed = 0.0
	clock_frozen = false
	if duration > 0.0:
		day_duration = duration
	else:
		day_duration = clampf(100.0 + 8.0 * float(day), 100.0, 240.0)
	_set_phase("open")
	print("DayManager 开始第 %d 天，营业 %.0f 秒" % [day_index, day_duration])


func set_clock_frozen(frozen: bool) -> void:
	clock_frozen = frozen


func _process(delta: float) -> void:
	if phase != "open" or clock_frozen:
		return
	_elapsed += delta
	var left := maxf(day_duration - _elapsed, 0.0)
	day_tick.emit(left)
	if left <= 0.0:
		_set_phase("result")


func _set_phase(next: String) -> void:
	phase = next
	phase_changed.emit(phase)
