extends Node

signal cup_updated
signal cup_finished(order_id: String)
signal recipe_error(reason: String)

var current_order_id: String = ""
var needed: Array[String] = []
var added: Array[String] = []
var shake_required: bool = false
var shake_count: int = 0


func reset_for_new_day() -> void:
	_clear()


func has_cup() -> bool:
	return current_order_id != ""


func start_cup(order: Order) -> bool:
	if has_cup():
		recipe_error.emit("先做完手里这杯")
		return false
	current_order_id = order.order_id
	needed = order.ingredients.duplicate()
	added.clear()
	shake_required = order.shake_required
	shake_count = 0
	cup_updated.emit()
	return true


func add_ingredient(ingredient_id: String) -> void:
	if current_order_id == "":
		recipe_error.emit("先点一张订单")
		return
	if added.size() >= needed.size():
		recipe_error.emit("料已经加完了")
		return
	var expect: String = needed[added.size()]
	if ingredient_id != expect:
		recipe_error.emit("下一料是%s" % expect)
		return
	added.append(ingredient_id)
	cup_updated.emit()


func shake() -> void:
	if current_order_id == "" or not shake_required:
		return
	if added.size() < needed.size():
		recipe_error.emit("料还没加完")
		return
	if shake_count >= 3:
		return
	shake_count += 1
	cup_updated.emit()


func seal_cup() -> bool:
	if current_order_id == "":
		recipe_error.emit("没有正在做的杯子")
		return false
	if added.size() < needed.size():
		recipe_error.emit("配方还没加完")
		return false
	if shake_required and shake_count < 3:
		recipe_error.emit("还要再摇 %d 下" % (3 - shake_count))
		return false
	var done := current_order_id
	_clear()
	cup_finished.emit(done)
	return true


func discard_cup() -> void:
	_clear()
	cup_updated.emit()


func next_ingredient() -> String:
	if added.size() >= needed.size():
		return ""
	return needed[added.size()]


func _clear() -> void:
	current_order_id = ""
	needed.clear()
	added.clear()
	shake_required = false
	shake_count = 0
