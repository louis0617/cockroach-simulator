extends Node2D

@onready var _day: Node = $DayManager
@onready var _orders: Node = $OrderManager
@onready var _recipe: Node = $RecipeManager
@onready var _economy: Node = $EconomyManager
@onready var _ui: CanvasLayer = $UI

var _filter: String = "all"
var _handover_open: bool = false
var _visitor_honest: bool = true
var _visitor_claim: String = ""
var _visitor_target: String = ""
var _selected_order_id: String = ""
var _visitor_wait: float = 0.0
var _thief_alive: bool = false
var _thief_claim: String = ""
var _thief_left: float = 0.0
var _thief_max: float = 10.0
var _thief_roll_done: bool = false
var _thief_disguise: int = 0
var _thief_platform: String = "self"
var _thief_items: Array[String] = []
var _hint_text: String = "点一张订单，按配方做完再封杯"

var _money_label: Label
var _day_label: Label
var _time_label: Label
var _rating_label: Label
var _customer_row: HBoxContainer
var _cup: Control
var _roach_layer: Control
var _slipper: Node2D
var _counter: ColorRect
var _bins: Array[Button] = []
var _hint_label: Label
var _pickup_box: HBoxContainer
var _roach_spawn: float = 2.0
var _test_panel: Panel
var _test_spin: SpinBox
var _shift: ShiftBudget
var _last_rating: float = 5.0
var _tight_streak: int = 0
var _settled: bool = false
var _dirt: Dictionary = {}
var _soil: Dictionary = {}
var _stock: Dictionary = {}
var _wash_left: float = 0.0
var _wash_id: String = ""
var _restock_left: float = 0.0
var _restock_id: String = ""
var _rinse_left: float = 0.0
var _cup_dirty: bool = false
var _handover: Control
var _handover_line: Label
var _handover_list: VBoxContainer
var _result: Control
var _result_body: Label
var _start: Control


func _ready() -> void:
	randomize()
	_build_ui()
	_day.phase_changed.connect(_on_phase)
	_day.day_tick.connect(_on_tick)
	_orders.order_created.connect(func(_o: Order) -> void: _rebuild_orders())
	_orders.order_status_changed.connect(_on_order_status)
	_orders.order_expired.connect(_on_order_expired)
	_recipe.cup_updated.connect(_refresh_station)
	_recipe.cup_finished.connect(_on_cup_finished)
	_recipe.recipe_error.connect(_set_hint)
	_economy.economy_changed.connect(_refresh_hud)
	_refresh_hud()
	_rebuild_orders()
	_refresh_station()


func _process(delta: float) -> void:
	if _day.phase != "open":
		return
	_tick_roaches(delta)
	_tick_chores(delta)
	_orders.tick(delta, _day.day_index)
	_tick_thief(delta)
	if _orders.ready_orders().is_empty():
		_visitor_wait = 0.0
		return
	if _thief_alive or _thief_roll_done:
		return
	_visitor_wait += delta
	if _visitor_wait >= 1.2:
		_visitor_wait = 0.0
		_thief_roll_done = true
		if _shift != null and _shift.rng.randf() < _shift.thief_chance:
			_spawn_thief()


func _on_phase(phase: String) -> void:
	if phase == "result":
		_close_handover(false)
		_show_result()


func _on_tick(time_left: float) -> void:
	var total_seconds := int(time_left)
	_time_label.text = "剩余 %d:%02d" % [int(float(total_seconds) / 60.0), total_seconds % 60]
	if _customer_row == null:
		return
	for child in _customer_row.get_children():
		var order: Order = _orders.get_order(child.order_id)
		if order == null:
			continue
		child.seconds_left = maxi(int(ceil(order.time_left)), 0)
		if order.time_limit > 0.0:
			child.patience = clampf(order.time_left / order.time_limit, 0.0, 1.0)
		child.queue_redraw()


func _on_order_status(order: Order, _old_status: String, new_status: String) -> void:
	if new_status == "failed":
		if _recipe.current_order_id == order.order_id:
			_recipe.discard_cup()
		_economy.add_fine(_fine(10))
		_economy.add_review(false)
		_set_hint("%s 超时了，差评" % order.order_id)
	_rebuild_orders()
	_refresh_pickup()
	_refresh_station()


func _on_order_expired(order: Order) -> void:
	print("OrderManager 超时 %s" % order.order_id)


func _on_cup_finished(order_id: String) -> void:
	_orders.mark_ready(order_id)
	_thief_roll_done = false
	_set_hint("把这杯拖到单号对得上的客人身上")
	_refresh_station()
	_refresh_pickup()


func _start_day() -> void:
	_start.hide()
	_result.hide()
	_settled = false
	_shift = ShiftBudget.roll(_day.day_index, _last_rating, _tight_streak)
	_orders.reset_for_new_day()
	_orders.apply_shift(_shift.interval, _shift.concurrent, _shift.ingredients, _shift.patience, _shift.price_bonus, _shift.price_mul, _shift.rng)
	_recipe.reset_for_new_day()
	_economy.reset_for_new_day()
	_close_handover(false)
	_cup_dirty = false
	_wash_left = 0.0
	_restock_left = 0.0
	_rinse_left = 0.0
	_init_supplies()
	_day.start_day(_day.day_index, _shift.duration)
	_orders.create_order(_day.day_index)
	_clear_roaches()
	_roach_spawn = 1.0
	for _i in _shift.roach_count:
		_spawn_roach()
	_refresh_hud()
	_rebuild_orders()
	_refresh_station()
	_refresh_pickup()
	_set_hint("第 %d 天 · %s。拖杯子给对得上的客人，假单号用拖鞋打" % [_day.day_index, _shift.modifier_name])


func _next_day() -> void:
	_day.day_index += 1
	_start_day()


func _build_test_jump(root: Control) -> void:
	var open := Button.new()
	open.text = "测试"
	open.position = Vector2(600, 12)
	open.size = Vector2(104, 40)
	open.z_index = 30
	open.add_theme_font_size_override("font_size", 18)
	open.pressed.connect(func() -> void:
		_test_panel.visible = not _test_panel.visible
		if _test_spin != null:
			_test_spin.value = _day.day_index
	)
	root.add_child(open)
	_test_panel = Panel.new()
	_test_panel.position = Vector2(300, 64)
	_test_panel.size = Vector2(400, 168)
	_test_panel.visible = false
	_test_panel.z_index = 31
	root.add_child(_test_panel)
	var label := Label.new()
	label.text = "跳到指定天数。按这一天的正常预算开，不受上一天评分影响。"
	label.position = Vector2(16, 12)
	label.size = Vector2(368, 56)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	_test_panel.add_child(label)
	_test_spin = SpinBox.new()
	_test_spin.min_value = 1
	_test_spin.max_value = 99
	_test_spin.step = 1
	_test_spin.rounded = true
	_test_spin.value = 1
	_test_spin.position = Vector2(16, 80)
	_test_spin.size = Vector2(200, 44)
	_test_panel.add_child(_test_spin)
	var jump := Button.new()
	jump.text = "跳到这天"
	jump.position = Vector2(232, 80)
	jump.size = Vector2(152, 44)
	jump.add_theme_font_size_override("font_size", 18)
	jump.pressed.connect(_jump_to_typed_day)
	_test_panel.add_child(jump)


func _jump_to_typed_day() -> void:
	if _test_spin == null:
		return
	_day.day_index = maxi(int(_test_spin.value), 1)
	_last_rating = 5.0
	_tight_streak = 0
	if _test_panel != null:
		_test_panel.hide()
	_start_day()


func _spawn_thief() -> void:
	var waiting: Array[Order] = _orders.ready_orders()
	if waiting.is_empty() or _thief_alive:
		return
	var target: Order = waiting[randi() % waiting.size()]
	_thief_claim = _fake_id(target.order_id)
	_thief_alive = true
	_thief_max = 10.0 if _shift == null else _shift.thief_time
	_thief_left = _thief_max
	_thief_disguise = _disguise_level()
	_thief_platform = target.platform
	_thief_items = target.ingredients.duplicate()
	_rebuild_orders()
	_set_hint("有人报了对不上的单号，用拖鞋打走")


func _tick_thief(delta: float) -> void:
	if not _thief_alive or _customer_row == null:
		return
	_thief_left -= delta
	for child in _customer_row.get_children():
		if child.is_thief:
			child.patience = clampf(_thief_left / _thief_max, 0.0, 1.0)
			child.seconds_left = maxi(int(ceil(_thief_left)), 0)
			child.queue_redraw()
	if _thief_left > 0.0:
		return
	var waiting: Array[Order] = _orders.ready_orders()
	if not waiting.is_empty():
		var stolen: Order = waiting[0]
		var loss: int = stolen.value()
		_orders.mark_stolen(stolen.order_id)
		_economy.add_stolen_loss(loss)
		_economy.add_review(false)
		_set_hint("假单号的人把杯子拿走了 -%d" % loss)
		_refresh_pickup()
	else:
		_set_hint("那个人等不及走了")
	_dismiss_thief()


func _give_to_customer(cup_order_id: String, pawn: Control) -> void:
	var selected: Order = _orders.get_order(cup_order_id)
	if selected == null:
		return
	if pawn.is_thief:
		var loss: int = selected.value()
		_orders.mark_stolen(selected.order_id)
		_economy.add_stolen_loss(loss)
		_economy.add_review(false)
		_set_hint("杯子给错人了，被拿走 -%d" % loss)
		_dismiss_thief()
		_refresh_pickup()
		return
	if cup_order_id == pawn.order_id:
		var gain: int = selected.value()
		_orders.mark_taken(selected.order_id)
		_economy.add_revenue(gain)
		_economy.add_review(true)
		_set_hint("交对了 +%d" % gain)
	else:
		_orders.mark_complaint(selected.order_id)
		var cost := _fine(20)
		_economy.add_fine(cost)
		_economy.add_review(false)
		_set_hint("这杯不是他的，差评 -%d" % cost)
	_refresh_pickup()
	_rebuild_orders()


func _disguise_level() -> int:
	var day: int = _day.day_index
	var level := 0
	if day <= 1:
		level = 0
	elif day == 2:
		level = 1
	elif day == 3:
		level = 2
	else:
		level = 3
	if _shift != null:
		level = mini(level + _shift.disguise_bonus, 3)
	return level


func _catch_thief() -> void:
	if not _thief_alive:
		return
	_economy.add_bonus(15)
	_set_hint("拖鞋把报假单号的人打走了 +15")
	_dismiss_thief()


func _dismiss_thief() -> void:
	_thief_alive = false
	_thief_claim = ""
	_thief_left = 0.0
	_thief_items.clear()
	_rebuild_orders()


func _fake_id(real_id: String) -> String:
	if real_id.length() < 2:
		return real_id + "9"
	var swapped := real_id.substr(0, real_id.length() - 2) + real_id.substr(real_id.length() - 1, 1) + real_id.substr(real_id.length() - 2, 1)
	if swapped == real_id:
		swapped = real_id.substr(0, real_id.length() - 1) + "0"
	return swapped


func _fill_handover() -> void:
	var who := "到店喊"
	if _visitor_claim.begins_with("JS-"):
		who = "急送达"
	elif _visitor_claim.begins_with("EB-"):
		who = "饿不饿"
	_handover_line.text = "对方说：我是%s的，取 %s" % [who, _visitor_claim]
	for child in _handover_list.get_children():
		child.queue_free()
	for order in _orders.ready_orders():
		var btn := Button.new()
		btn.text = "%s  %s" % [order.order_id, order.display_name]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0, 64)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_select_order.bind(order.order_id, btn))
		_handover_list.add_child(btn)


func _select_order(order_id: String, btn: Button) -> void:
	_selected_order_id = order_id
	for child in _handover_list.get_children():
		if child is Button:
			(child as Button).modulate = Color.WHITE
	btn.modulate = Color("FFE082")


func _confirm_handover() -> void:
	if _selected_order_id == "":
		_set_hint("先选一杯再给")
		return
	var selected: Order = _orders.get_order(_selected_order_id)
	if selected == null:
		return
	if not _visitor_honest:
		var loss: int = selected.value()
		_orders.mark_stolen(selected.order_id)
		_economy.add_stolen_loss(loss)
		_economy.add_review(false)
		_set_hint("单号是假的，这杯被拿走了 -%d" % loss)
		_close_handover(true)
		return
	if selected.order_id == _visitor_claim:
		var gain: int = selected.value()
		_orders.mark_taken(selected.order_id)
		_economy.add_revenue(gain)
		_economy.add_review(true)
		_set_hint("核对正确 +%d" % gain)
	else:
		_orders.mark_complaint(selected.order_id)
		_economy.add_fine(_fine(20))
		_economy.add_review(false)
		_set_hint("给错杯了，差评 -20")
	_close_handover(true)


func _reject_handover() -> void:
	if not _visitor_honest:
		_orders.cancel_handover(_visitor_target)
		_economy.add_bonus(15)
		_set_hint("报错单号，赶走了 +15")
	else:
		_orders.mark_complaint(_visitor_target)
		_economy.add_fine(_fine(20))
		_economy.add_review(false)
		_set_hint("真客人被拒绝，差评 -20")
	_close_handover(true)


func _close_handover(clear_target: bool) -> void:
	_handover_open = false
	_visitor_target = ""
	_visitor_claim = ""
	_selected_order_id = ""
	_thief_alive = false
	_thief_claim = ""
	if not clear_target:
		pass
	_day.set_clock_frozen(false)
	_orders.set_clock_frozen(false)
	if _handover != null:
		_handover.hide()
	_refresh_pickup()


func _show_result() -> void:
	if _shift != null and not _settled:
		_economy.charge_rent(_shift.rent)
		var preview: Dictionary = _economy.summary()
		var revenue: int = int(preview["revenue"])
		var fine: int = int(preview["platform_fine"])
		var stolen: int = int(preview["stolen_loss"])
		var restock: int = int(preview["restock"])
		var rent: int = int(preview["rent"])
		var net: int = revenue - fine - stolen - restock - rent
		var grade := _grade(net, rent, float(preview["rating_after"]))
		if grade == "紧":
			_tight_streak += 1
		else:
			_tight_streak = 0
		_last_rating = float(preview["rating_after"])
		_settled = true
	var data: Dictionary = _economy.summary()
	var revenue_now: int = int(data["revenue"])
	var fine_now: int = int(data["platform_fine"])
	var stolen_now: int = int(data["stolen_loss"])
	var restock_now: int = int(data["restock"])
	var rent_now: int = int(data["rent"])
	var net_now: int = revenue_now - fine_now - stolen_now - restock_now - rent_now
	var grade_now: String = _grade(net_now, rent_now, float(data["rating_after"]))
	var shift_name: String = "普通夜班" if _shift == null else str(_shift.modifier_name)
	_result_body.text = "第 %d 天 · %s\n本日：%s\n营收 +%d\n罚款 -%d\n被拿走 -%d\n补货 -%d\n租金 -%d\n净利 %d\n评分 %.1f\n手头 %d" % [
		_day.day_index, shift_name, grade_now,
		revenue_now, fine_now, stolen_now, restock_now, rent_now, net_now,
		float(data["rating_after"]), int(data["money"]),
	]
	_result.show()


func _grade(net: int, rent: int, rating: float) -> String:
	if net < int(round(float(rent) * 0.7)) or rating < 3.0:
		return "紧"
	if net >= rent and rating >= 4.0:
		return "顺"
	return "平"


func _fine(amount: int) -> int:
	if _shift == null:
		return amount
	return int(round(float(amount) * _shift.fine_mul))


func _try_make(order_id: String) -> void:
	if _handover_open or _day.phase != "open":
		return
	var order: Order = _orders.get_order(order_id)
	if order == null:
		return
	var recipe := "、".join(order.ingredients)
	if not _orders.start_making(order_id):
		_set_hint("%s：%s" % [order.order_id, recipe])
		return
	_recipe.start_cup(order)
	_cup_dirty = false
	_set_hint("%s：%s" % [order.order_id, recipe])


func _set_hint(text: String) -> void:
	_hint_text = text
	if _hint_label != null:
		_hint_label.text = text


func _refresh_hud() -> void:
	_money_label.text = "¥ %d" % _economy.money
	_day_label.text = "第 %d 天" % _day.day_index
	_rating_label.text = "评分 %.1f" % _economy.rating


func _refresh_station() -> void:
	if _cup == null:
		return
	if not _recipe.has_cup():
		_cup.show_layers([], false)
		_cup.modulate = Color.WHITE
		return
	_cup.show_layers(_recipe.added, false)
	_cup.modulate = Color(0.62, 0.5, 0.38) if _cup_dirty else Color.WHITE
	var next: String = _recipe.next_ingredient()
	var needed: Array = _recipe.needed
	var added: Array = _recipe.added
	var left: PackedStringArray = PackedStringArray()
	for i in range(added.size(), needed.size()):
		left.append(str(needed[i]))
	if next != "":
		_set_hint("还要：%s" % "、".join(left))
	elif _recipe.shake_required and _recipe.shake_count < 3:
		_set_hint("摇匀 %d / 3" % _recipe.shake_count)
	else:
		_set_hint("可以封杯了")


func _rebuild_orders() -> void:
	if _customer_row == null:
		return
	for child in _customer_row.get_children():
		child.queue_free()
	var shown := 0
	for order in _orders.active_orders:
		if shown >= 3:
			break
		if order.status != "pending" and order.status != "making" and order.status != "ready" and order.status != "handover_pending":
			continue
		var pawn := preload("res://scripts/view/face_pawn.gd").new()
		pawn.custom_minimum_size = Vector2(210, 190)
		pawn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pawn.setup(order)
		pawn.picked.connect(_try_make)
		pawn.cup_dropped.connect(_give_to_customer.bind(pawn))
		_customer_row.add_child(pawn)
		shown += 1
	if _thief_alive and shown < 4:
		var thief := preload("res://scripts/view/face_pawn.gd").new()
		thief.custom_minimum_size = Vector2(210, 190)
		thief.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		thief.setup_thief(_thief_claim, clampf(_thief_left / _thief_max, 0.0, 1.0), _thief_disguise, _thief_platform, _thief_items)
		thief.cup_dropped.connect(_give_to_customer.bind(thief))
		_customer_row.add_child(thief)


func _refresh_pickup() -> void:
	if _pickup_box == null:
		return
	for child in _pickup_box.get_children():
		child.queue_free()
	for order in _orders.ready_orders():
		var cup := preload("res://scripts/view/drag_cup.gd").new()
		cup.setup(order.order_id, order.ingredients)
		_pickup_box.add_child(cup)


func _tick_roaches(delta: float) -> void:
	if _roach_layer == null or _shift == null:
		return
	_roach_spawn -= delta
	if _roach_spawn <= 0.0 and _roach_layer.get_child_count() < _shift.roach_count:
		_spawn_roach()
		_roach_spawn = _shift.roach_interval
	var spots: Array[Vector2] = _roach_spots()
	var cup_at := Vector2.ZERO
	var cup_ready: bool = _cup != null and _recipe.has_cup()
	if cup_ready:
		cup_at = _cup.get_global_rect().get_center()
	var soil_changed := false
	for child in _roach_layer.get_children():
		if spots.size() > 0 and child._goal_time > 3.2:
			child.set_goal(spots[randi() % spots.size()])
		var on_cup: bool = cup_ready and child.global_position.distance_to(cup_at) <= 78.0
		if on_cup:
			child.spoil += delta
			if _shift.rinse and child.spoil >= 0.4:
				if not _cup_dirty:
					_cup_dirty = true
					_set_hint("杯子被爬了，封杯前要涮")
					_refresh_station()
			if child.spoil >= _shift.cup_spoil:
				child.spoil = 0.0
				_cup_dirty = false
				_recipe.discard_cup()
				_set_hint("蟑螂钻进杯子了，这杯倒掉")
		else:
			child.spoil = 0.0
		if _shift.soil_seconds <= 0.0:
			continue
		var bin_id := _bin_under(child.global_position)
		if bin_id == "":
			continue
		var piled: float = float(_soil.get(bin_id, 0.0)) + delta
		if piled < _shift.soil_seconds:
			_soil[bin_id] = piled
			continue
		_soil[bin_id] = 0.0
		_dirt[bin_id] = int(_dirt.get(bin_id, 0)) + 1
		if _shift.stock >= 0 and int(_stock.get(bin_id, 0)) > 0:
			_stock[bin_id] = int(_stock.get(bin_id, 0)) - 1
		soil_changed = true
		_set_hint("%s被蟑螂爬了" % bin_id)
	if soil_changed:
		_refresh_bins()


func _bin_under(at: Vector2) -> String:
	var found := ""
	var best := 70.0
	for bin in _bins:
		var gap := bin.get_global_rect().get_center().distance_to(at)
		if gap < best:
			best = gap
			found = str(bin.get("ingredient_id"))
	return found


func _roach_spots() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	var to_local := _roach_layer.get_global_transform().affine_inverse()
	if _cup != null:
		spots.append(to_local * _cup.get_global_rect().get_center())
	for bin in _bins:
		spots.append(to_local * bin.get_global_rect().get_center())
	return spots


func _spawn_roach() -> void:
	var roach := preload("res://scripts/view/shop_roach.gd").new()
	roach.speed = 78.0 * (1.0 + 0.04 * float(mini(_day.day_index, 15)))
	roach.bounds = Rect2(Vector2.ZERO, _roach_layer.size)
	roach.position = Vector2(randf_range(40.0, 640.0), randf_range(180.0, 520.0))
	_roach_layer.add_child(roach)
	var spots := _roach_spots()
	if spots.size() > 0:
		roach.set_goal(spots[randi() % spots.size()])


func _clear_roaches() -> void:
	if _roach_layer == null:
		return
	for child in _roach_layer.get_children():
		child.queue_free()


func _init_supplies() -> void:
	_dirt.clear()
	_soil.clear()
	_stock.clear()
	var portions: int = _shift.stock
	for item in IngredientCatalog.IDS:
		_dirt[item] = 0
		_soil[item] = 0.0
		_stock[item] = portions
	if _shift.shortage and portions > 0:
		var picks: Array[String] = []
		var guard := 0
		while picks.size() < 2 and guard < 12:
			guard += 1
			var item: String = IngredientCatalog.IDS[_shift.rng.randi_range(0, IngredientCatalog.IDS.size() - 1)]
			if not picks.has(item):
				picks.append(item)
				_stock[item] = maxi(1, int(float(portions) / 2.0))
	_refresh_bins()


func _refresh_bins() -> void:
	var track: bool = _shift != null and _shift.stock >= 0
	for bin in _bins:
		var item := str(bin.get("ingredient_id"))
		bin.call("set_supply", int(_dirt.get(item, 0)), int(_stock.get(item, -1)), track)


func _on_bin_pressed(item: String) -> void:
	if _wash_left > 0.0 or _restock_left > 0.0:
		_set_hint("手头的活还没做完")
		return
	if int(_dirt.get(item, 0)) >= 3:
		_begin_wash(item)
		return
	if _shift != null and _shift.stock >= 0 and int(_stock.get(item, 0)) <= 0:
		_begin_restock(item)
		return
	_recipe.add_ingredient(item)


func _start_wash_dirtiest() -> void:
	var worst := ""
	var layers := 0
	for item in _dirt.keys():
		var count: int = int(_dirt[item])
		if count > layers:
			layers = count
			worst = str(item)
	if worst == "" or layers <= 0:
		_set_hint("碗是干净的")
		return
	_begin_wash(worst)


func _begin_wash(item: String) -> void:
	if _shift == null or _shift.soil_seconds <= 0.0:
		_set_hint("这天还不用洗碗")
		return
	if int(_dirt.get(item, 0)) <= 0:
		_set_hint("这只碗是干净的")
		return
	_wash_id = item
	_wash_left = _shift.wash_time
	_set_hint("正在洗%s" % item)


func _begin_restock(item: String) -> void:
	if _shift == null or _shift.stock < 0:
		return
	if _economy.money < _shift.restock_cost:
		_set_hint("补一份%s要 %d，手头不够" % [item, _shift.restock_cost])
		return
	_economy.add_restock(_shift.restock_cost)
	_restock_id = item
	_restock_left = _shift.restock_time
	_set_hint("正在补%s，花了 %d" % [item, _shift.restock_cost])


func _start_rinse() -> void:
	if _shift == null or not _shift.rinse:
		_set_hint("这天不用涮杯")
		return
	if not _recipe.has_cup():
		_set_hint("没有正在做的杯子")
		return
	if not _cup_dirty:
		_set_hint("杯子是干净的")
		return
	_rinse_left = _shift.rinse_time
	_set_hint("正在涮杯")


func _try_seal() -> void:
	if _shift != null and _shift.rinse and _cup_dirty and _recipe.has_cup():
		var order_id: String = _recipe.current_order_id
		_recipe.discard_cup()
		_cup_dirty = false
		_orders.mark_complaint(order_id)
		var cost := _fine(20)
		_economy.add_fine(cost)
		_economy.add_review(false)
		_set_hint("没涮杯就封，客人投诉 -%d" % cost)
		return
	_recipe.seal_cup()


func _tick_chores(delta: float) -> void:
	if _wash_left > 0.0:
		_wash_left -= delta
		if _wash_left <= 0.0:
			_wash_left = 0.0
			_dirt[_wash_id] = 0
			_soil[_wash_id] = 0.0
			_refresh_bins()
			_set_hint("%s洗净了" % _wash_id)
			_wash_id = ""
	if _restock_left > 0.0:
		_restock_left -= delta
		if _restock_left <= 0.0:
			_restock_left = 0.0
			_stock[_restock_id] = int(_stock.get(_restock_id, 0)) + 1
			_refresh_bins()
			_set_hint("%s补上了一份" % _restock_id)
			_restock_id = ""
	if _rinse_left > 0.0:
		_rinse_left -= delta
		if _rinse_left <= 0.0:
			_rinse_left = 0.0
			_cup_dirty = false
			_refresh_station()
			_set_hint("杯子涮干净了")


func _is_click(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _input(event: InputEvent) -> void:
	if _day.phase != "open" or _slipper == null:
		return
	if _start.visible or _result.visible:
		return
	if not _is_click(event):
		return
	var at := get_global_mouse_position()
	if get_viewport().gui_is_dragging() or _over_pickup(at):
		return
	if _thief_under(at) != null:
		_slipper.try_slam(at)
		get_viewport().set_input_as_handled()
		return
	if _counter == null or not _counter.get_global_rect().has_point(at):
		return
	var aiming_roach := false
	for child in _roach_layer.get_children():
		if child.global_position.distance_to(at) <= 42.0:
			aiming_roach = true
			break
	var on_bin := false
	for bin in _bins:
		if bin.get_global_rect().has_point(at):
			on_bin = true
			break
	if not aiming_roach and on_bin:
		return
	_slipper.try_slam(at)
	if aiming_roach or not on_bin:
		get_viewport().set_input_as_handled()


func _over_pickup(at: Vector2) -> bool:
	if _pickup_box == null:
		return false
	if _pickup_box.get_global_rect().has_point(at):
		return true
	for child in _pickup_box.get_children():
		if child is Control and (child as Control).get_global_rect().has_point(at):
			return true
	return false


func _thief_under(at: Vector2) -> Control:
	if not _thief_alive or _customer_row == null:
		return null
	for child in _customer_row.get_children():
		if child.is_thief and child.get_global_rect().has_point(at):
			return child
	return null


func _on_slipper_hit(at: Vector2, radius: float) -> void:
	if _thief_under(at) != null:
		_catch_thief()
		return
	var hit := false
	for child in _roach_layer.get_children():
		if not child.alive:
			continue
		if child.global_position.distance_to(at) <= radius + 16.0:
			child.smash()
			hit = true
	if hit:
		_set_hint("拖鞋拍扁了一只")
	else:
		_set_hint("拖鞋拍空了")


func _status_label(status: String) -> String:
	match status:
		"pending":
			return "待做"
		"making":
			return "制作中"
		"ready":
			return "可取"
		"handover_pending":
			return "核对中"
		_:
			return status


func _status_color(status: String) -> Color:
	match status:
		"making":
			return Color("E65100")
		"ready":
			return Color("2E7D32")
		"handover_pending":
			return Color("1565C0")
		_:
			return Color("4E342E")


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(root)

	var bg := ColorRect.new()
	bg.color = Color("F6E7D4")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var top := HBoxContainer.new()
	top.position = Vector2(16, 16)
	top.size = Vector2(688, 40)
	top.add_theme_constant_override("separation", 16)
	root.add_child(top)
	_day_label = _hud_label("第 1 天")
	_time_label = _hud_label("剩余 2:00")
	_money_label = _hud_label("¥ 0")
	_rating_label = _hud_label("评分 5.0")
	top.add_child(_day_label)
	top.add_child(_time_label)
	top.add_child(_money_label)
	top.add_child(_rating_label)

	_customer_row = HBoxContainer.new()
	_customer_row.position = Vector2(12, 58)
	_customer_row.size = Vector2(696, 200)
	_customer_row.add_theme_constant_override("separation", 8)
	root.add_child(_customer_row)

	_hint_label = Label.new()
	_hint_label.position = Vector2(20, 262)
	_hint_label.size = Vector2(680, 40)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", 20)
	_hint_label.add_theme_color_override("font_color", Color("6D4C41"))
	_hint_label.text = _hint_text
	root.add_child(_hint_label)

	var counter := ColorRect.new()
	counter.position = Vector2(16, 304)
	counter.size = Vector2(688, 820)
	counter.color = Color("C4A574")
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(counter)
	_counter = counter

	_cup = preload("res://scripts/view/cup_view.gd").new()
	_cup.position = Vector2(284, 330)
	_cup.size = Vector2(150, 170)
	_cup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_cup)

	_roach_layer = Control.new()
	_roach_layer.position = Vector2(16, 304)
	_roach_layer.size = Vector2(688, 760)
	_roach_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roach_layer.z_index = 4
	root.add_child(_roach_layer)

	var shelf := GridContainer.new()
	shelf.position = Vector2(20, 700)
	shelf.size = Vector2(680, 360)
	shelf.columns = 4
	shelf.add_theme_constant_override("h_separation", 6)
	shelf.add_theme_constant_override("v_separation", 4)
	shelf.z_index = 2
	root.add_child(shelf)
	_bins.clear()
	for item in IngredientCatalog.IDS:
		var bin := preload("res://scripts/view/ingredient_bin.gd").new()
		bin.setup(item)
		bin.pressed.connect(_on_bin_pressed.bind(item))
		shelf.add_child(bin)
		_bins.append(bin)

	_pickup_box = HBoxContainer.new()
	_pickup_box.position = Vector2(470, 320)
	_pickup_box.size = Vector2(220, 200)
	_pickup_box.z_index = 6
	_pickup_box.add_theme_constant_override("separation", 8)
	root.add_child(_pickup_box)

	var actions := HBoxContainer.new()
	actions.position = Vector2(24, 1140)
	actions.size = Vector2(672, 64)
	actions.add_theme_constant_override("separation", 12)
	root.add_child(actions)
	var shake := Button.new()
	shake.text = "摇匀"
	shake.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shake.custom_minimum_size = Vector2(0, 64)
	shake.add_theme_font_size_override("font_size", 24)
	shake.pressed.connect(func() -> void: _recipe.shake())
	var seal := Button.new()
	seal.text = "封杯"
	seal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seal.custom_minimum_size = Vector2(0, 64)
	seal.add_theme_font_size_override("font_size", 24)
	seal.pressed.connect(_try_seal)
	actions.add_child(shake)
	actions.add_child(seal)
	var wash := Button.new()
	wash.text = "洗涤"
	wash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wash.custom_minimum_size = Vector2(0, 64)
	wash.add_theme_font_size_override("font_size", 24)
	wash.pressed.connect(_start_wash_dirtiest)
	var rinse := Button.new()
	rinse.text = "涮杯"
	rinse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rinse.custom_minimum_size = Vector2(0, 64)
	rinse.add_theme_font_size_override("font_size", 24)
	rinse.pressed.connect(_start_rinse)
	actions.add_child(wash)
	actions.add_child(rinse)

	_slipper = preload("res://scenes/slipper.tscn").instantiate()
	_slipper.z_index = 40
	_ui.add_child(_slipper)
	_slipper.slammed.connect(_on_slipper_hit)

	_build_handover(root)
	_build_result(root)
	_build_start(root)
	_build_test_jump(root)


func _hud_label(text: String) -> Label:
	var lab := Label.new()
	lab.text = text
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.add_theme_font_size_override("font_size", 20)
	lab.add_theme_color_override("font_color", Color("4E342E"))
	return lab


func _filter_button(text: String, platform: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func() -> void:
		_filter = platform
		_rebuild_orders()
	)
	return btn


func _build_handover(root: Control) -> void:
	_handover = ColorRect.new()
	_handover.color = Color(0.1, 0.07, 0.05, 0.55)
	_handover.set_anchors_preset(Control.PRESET_FULL_RECT)
	_handover.visible = false
	root.add_child(_handover)
	var panel := Panel.new()
	panel.position = Vector2(36, 280)
	panel.size = Vector2(648, 720)
	_handover.add_child(panel)
	_handover_line = Label.new()
	_handover_line.position = Vector2(20, 20)
	_handover_line.size = Vector2(608, 80)
	_handover_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_handover_line.add_theme_font_size_override("font_size", 24)
	panel.add_child(_handover_line)
	var tip := Label.new()
	tip.text = "待取的杯子"
	tip.position = Vector2(20, 110)
	tip.size = Vector2(608, 32)
	tip.add_theme_font_size_override("font_size", 18)
	panel.add_child(tip)
	_handover_list = VBoxContainer.new()
	_handover_list.position = Vector2(20, 150)
	_handover_list.size = Vector2(608, 400)
	_handover_list.add_theme_constant_override("separation", 8)
	panel.add_child(_handover_list)
	var row := HBoxContainer.new()
	row.position = Vector2(20, 620)
	row.size = Vector2(608, 64)
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var ok := Button.new()
	ok.text = "确认给餐"
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.custom_minimum_size = Vector2(0, 64)
	ok.add_theme_font_size_override("font_size", 22)
	ok.pressed.connect(_confirm_handover)
	var no := Button.new()
	no.text = "拒绝"
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.custom_minimum_size = Vector2(0, 64)
	no.add_theme_font_size_override("font_size", 22)
	no.pressed.connect(_reject_handover)
	row.add_child(ok)
	row.add_child(no)


func _build_result(root: Control) -> void:
	_result = ColorRect.new()
	_result.color = Color(0.1, 0.07, 0.05, 0.62)
	_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result.visible = false
	root.add_child(_result)
	var panel := Panel.new()
	panel.position = Vector2(50, 340)
	panel.size = Vector2(620, 560)
	_result.add_child(panel)
	var title := Label.new()
	title.text = "打烊了"
	title.position = Vector2(24, 24)
	title.size = Vector2(572, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	panel.add_child(title)
	_result_body = Label.new()
	_result_body.position = Vector2(36, 100)
	_result_body.size = Vector2(548, 320)
	_result_body.add_theme_font_size_override("font_size", 22)
	panel.add_child(_result_body)
	var next := Button.new()
	next.text = "下一天"
	next.position = Vector2(36, 450)
	next.size = Vector2(548, 72)
	next.add_theme_font_size_override("font_size", 28)
	next.pressed.connect(_next_day)
	panel.add_child(next)


func _build_start(root: Control) -> void:
	_start = ColorRect.new()
	_start.color = Color("F6E7D4")
	_start.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_start)
	var title := Label.new()
	title.text = "夜班奶茶铺"
	title.position = Vector2(40, 360)
	title.size = Vector2(640, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("4E342E"))
	_start.add_child(title)
	var desc := Label.new()
	desc.text = "做完一杯，听对方报单号。\n对上了才给。报错的人，别把茶递出去。"
	desc.position = Vector2(60, 450)
	desc.size = Vector2(600, 100)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", Color("6D4C41"))
	_start.add_child(desc)
	var go := Button.new()
	go.text = "开店"
	go.position = Vector2(180, 600)
	go.size = Vector2(360, 80)
	go.add_theme_font_size_override("font_size", 32)
	go.pressed.connect(_start_day)
	_start.add_child(go)
