extends Node

signal cup_updated
signal recipe_error(reason: String)

var station_open: bool = false
var added: Array[String] = []
var water: float = 0.0
var water_done: bool = false
var shake_count: int = 0
var tainted: bool = false


func reset_for_new_day() -> void:
	station_open = false
	_clear_contents()


func open_station() -> void:
	station_open = true
	_clear_contents()


func has_cup() -> bool:
	return station_open


func add_ingredient(ingredient_id: String) -> void:
	if not station_open:
		recipe_error.emit("台上没有杯子")
		return
	if added.has(ingredient_id):
		recipe_error.emit("%s已经加过了" % ingredient_id)
		return
	added.append(ingredient_id)
	cup_updated.emit()


func add_water(amount: float) -> void:
	if not station_open or water_done:
		return
	water = minf(1.0, water + amount)
	if water >= 1.0:
		water_done = true
	cup_updated.emit()


func mark_tainted() -> void:
	if not station_open or tainted:
		return
	tainted = true
	cup_updated.emit()


func shake() -> void:
	if not station_open:
		recipe_error.emit("台上没有杯子")
		return
	if shake_count >= 4:
		recipe_error.emit("已经摇过头了")
		return
	shake_count += 1
	cup_updated.emit()


func recipe_key() -> String:
	var names: Array[String] = added.duplicate()
	names.sort()
	return "%s#s%d" % ["+".join(names), shake_count]


func snapshot_and_reset() -> Dictionary:
	var shot := {
		"items": added.duplicate(),
		"key": recipe_key(),
		"shakes": shake_count,
		"tainted": tainted,
	}
	_clear_contents()
	cup_updated.emit()
	return shot


func discard_cup() -> void:
	_clear_contents()
	cup_updated.emit()


func _clear_contents() -> void:
	added.clear()
	water = 0.0
	water_done = false
	shake_count = 0
	tainted = false
