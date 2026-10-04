extends Node

signal coins_changed(value: int)
signal upgrade_changed

const SAVE_PATH := "user://save.cfg"
const SLIPPER_COSTS: Array[int] = [25, 60, 120, 220]
const SPAWN_COSTS: Array[int] = [30, 80, 160]
const XRAY_COST := 90

var coins: int = 0
var best_combo: int = 0
var slipper_level: int = 0
var spawn_level: int = 0
var xray: bool = false


func _ready() -> void:
	_load()
	coins_changed.emit(coins)


func slipper_scale() -> float:
	return 1.0 + float(slipper_level) * 0.28


func slipper_radius() -> float:
	return 52.0 * slipper_scale()


func spawn_interval() -> float:
	return maxf(1.15, 3.6 - float(spawn_level) * 0.7)


func max_roaches() -> int:
	return 4 + spawn_level * 2


func add_coins(amount: int) -> void:
	coins = maxi(coins + amount, 0)
	coins_changed.emit(coins)
	_save()


func try_buy_slipper() -> bool:
	if slipper_level >= SLIPPER_COSTS.size():
		return false
	var cost: int = SLIPPER_COSTS[slipper_level]
	if coins < cost:
		return false
	coins -= cost
	slipper_level += 1
	coins_changed.emit(coins)
	upgrade_changed.emit()
	_save()
	return true


func try_buy_spawn() -> bool:
	if spawn_level >= SPAWN_COSTS.size():
		return false
	var cost: int = SPAWN_COSTS[spawn_level]
	if coins < cost:
		return false
	coins -= cost
	spawn_level += 1
	coins_changed.emit(coins)
	upgrade_changed.emit()
	_save()
	return true


func try_buy_xray() -> bool:
	if xray:
		return false
	if coins < XRAY_COST:
		return false
	coins -= XRAY_COST
	xray = true
	coins_changed.emit(coins)
	upgrade_changed.emit()
	_save()
	return true


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("p", "coins", coins)
	cfg.set_value("p", "best_combo", best_combo)
	cfg.set_value("p", "slipper_level", slipper_level)
	cfg.set_value("p", "spawn_level", spawn_level)
	cfg.set_value("p", "xray", xray)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	coins = int(cfg.get_value("p", "coins", 0))
	best_combo = int(cfg.get_value("p", "best_combo", 0))
	slipper_level = int(cfg.get_value("p", "slipper_level", 0))
	spawn_level = int(cfg.get_value("p", "spawn_level", 0))
	xray = bool(cfg.get_value("p", "xray", false))
