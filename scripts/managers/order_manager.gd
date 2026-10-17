extends Node

signal order_created(order: Order)
signal order_status_changed(order: Order, old_status: String, new_status: String)
signal order_expired(order: Order)

var active_orders: Array[Order] = []
var clock_frozen: bool = false
var spawn_interval: float = 10.5
var max_open: int = 2
var ingredient_count: int = 1
var patience: float = 45.0
var price_bonus: int = 0
var price_mul: float = 1.0
var _spawn_wait: float = 0.0
var _rng: RandomNumberGenerator


func reset_for_new_day() -> void:
	active_orders.clear()
	clock_frozen = false
	_spawn_wait = 1.0


func apply_shift(interval: float, open_cap: int, ingredient_n: int, patience_seconds: float, bonus: int, mul: float, rng: RandomNumberGenerator) -> void:
	spawn_interval = interval
	max_open = open_cap
	ingredient_count = ingredient_n
	patience = patience_seconds
	price_bonus = bonus
	price_mul = mul
	_rng = rng


func set_clock_frozen(frozen: bool) -> void:
	clock_frozen = frozen


func tick(delta: float, day: int) -> void:
	if clock_frozen:
		return
	for order in active_orders:
		if order.status != "pending" and order.status != "making" and order.status != "ready" and order.status != "handover_pending":
			continue
		order.time_left -= delta
		if order.time_left <= 0.0:
			_set_status(order, "failed")
			order_expired.emit(order)
	_spawn_wait -= delta
	if _spawn_wait <= 0.0 and _open_count() < max_open:
		create_order(day)
		_spawn_wait = spawn_interval


func create_order(day: int) -> Order:
	var platforms: Array[String] = ["jisong", "ebu", "self"]
	var order := Order.new()
	order.platform = platforms[_rand_index(platforms.size())]
	order.order_id = _gen_order_id(order.platform)
	order.display_name = NameGenerator.generate(day, _rng)
	order.ingredients = _gen_ingredients(day)
	order.shake_required = _randf() < 0.45
	order.time_limit = patience
	order.time_left = order.time_limit
	order.status = "pending"
	var base_price := 12 + 4 * order.ingredients.size() + price_bonus
	order.price = int(round(float(base_price) * price_mul))
	active_orders.append(order)
	order_created.emit(order)
	print("OrderManager 新单 %s %s" % [order.order_id, order.display_name])
	return order


func start_making(order_id: String) -> bool:
	if _making_order() != null:
		return false
	var order := get_order(order_id)
	if order == null or order.status != "pending":
		push_warning("无法开始制作: %s" % order_id)
		return false
	_set_status(order, "making")
	return true


func mark_ready(order_id: String) -> void:
	var order := get_order(order_id)
	assert(order != null)
	if order.status != "making":
		return
	_set_status(order, "ready")


func begin_handover(order_id: String) -> void:
	var order := get_order(order_id)
	if order == null or order.status != "ready":
		return
	_set_status(order, "handover_pending")


func cancel_handover(order_id: String) -> void:
	var order := get_order(order_id)
	if order == null or order.status != "handover_pending":
		return
	_set_status(order, "ready")


func mark_taken(order_id: String) -> void:
	_finish(order_id, "taken")


func mark_stolen(order_id: String) -> void:
	_finish(order_id, "stolen")


func mark_complaint(order_id: String) -> void:
	_finish(order_id, "complaint")


func get_order(order_id: String) -> Order:
	for order in active_orders:
		if order.order_id == order_id:
			return order
	return null


func ready_orders() -> Array[Order]:
	var found: Array[Order] = []
	for order in active_orders:
		if order.status == "ready" or order.status == "handover_pending":
			found.append(order)
	return found


func _finish(order_id: String, status: String) -> void:
	var order := get_order(order_id)
	if order == null:
		return
	_set_status(order, status)


func _set_status(order: Order, next: String) -> void:
	var old := order.status
	if old == next:
		return
	order.status = next
	order_status_changed.emit(order, old, next)


func _making_order() -> Order:
	for order in active_orders:
		if order.status == "making":
			return order
	return null


func _open_count() -> int:
	var n := 0
	for order in active_orders:
		if order.status == "pending" or order.status == "making" or order.status == "ready" or order.status == "handover_pending":
			n += 1
	return n


func _randf() -> float:
	if _rng == null:
		return randf()
	return _rng.randf()


func _rand_index(size: int) -> int:
	if size <= 1:
		return 0
	if _rng == null:
		return randi() % size
	return _rng.randi_range(0, size - 1)


func _max_orders(_day: int) -> int:
	return max_open


func _spawn_interval(_day: int) -> float:
	return spawn_interval


func _gen_order_id(platform: String) -> String:
	var prefix := "喊-"
	if platform == "jisong":
		prefix = "JS-"
	elif platform == "ebu":
		prefix = "EB-"
	var number := 1000 + _rand_index(9000)
	var candidate := "%s%d" % [prefix, number]
	if get_order(candidate) != null:
		candidate = "%s%d" % [prefix, 1000 + _rand_index(9000)]
	return candidate


func _gen_ingredients(_day: int) -> Array[String]:
	var count := ingredient_count
	var bag: Array[String] = []
	var guard := 0
	while bag.size() < count and guard < 20:
		guard += 1
		var item: String = IngredientCatalog.IDS[_rand_index(IngredientCatalog.IDS.size())]
		if not bag.has(item):
			bag.append(item)
	return bag
