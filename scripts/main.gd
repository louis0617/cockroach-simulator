extends Node2D

const CANDY_SCENE := preload("res://scenes/candy.tscn")
const ROACH_SCENE := preload("res://scenes/roach.tscn")
const CANDY_COUNT := 88

@onready var _world: Node2D = $World
@onready var _candies: Node2D = $World/Candies
@onready var _roaches: Node2D = $World/Roaches
@onready var _stains: Node2D = $World/Stains
@onready var _slipper: Node2D = $Slipper
@onready var _coin_label: Label = $HUD/Top/CoinLabel
@onready var _combo_label: Label = $HUD/Top/ComboLabel
@onready var _hint: Label = $HUD/Hint
@onready var _keep_label: Label = $HUD/Goals/KeepLabel
@onready var _cover_label: Label = $HUD/Goals/CoverLabel
@onready var _eat_label: Label = $HUD/Goals/EatLabel
@onready var _wipe_btn: Button = $HUD/Top/WipeButton
@onready var _shop: Control = $HUD/Shop
@onready var _start: Control = $HUD/Start
@onready var _result: Control = $HUD/Result
@onready var _result_title: Label = $HUD/Result/Panel/VBox/Title
@onready var _result_desc: Label = $HUD/Result/Panel/VBox/Desc
@onready var _btn_slipper: Button = $HUD/Shop/Panel/VBox/SlipperBtn
@onready var _btn_spawn: Button = $HUD/Shop/Panel/VBox/SpawnBtn
@onready var _btn_xray: Button = $HUD/Shop/Panel/VBox/XrayBtn

var _playing := false
var _settling := false
var _level := 1
var _combo := 0
var _combo_time := 0.0
var _roaches_left := 0
var _wipes := 2
var _wipe_mode := false
var _eat_cd := 2.6
var _plate := Rect2(86, 860, 548, 310)
var _pile := Rect2(110, 900, 500, 250)


func _ready() -> void:
	randomize()
	_build_bowl()
	_slipper.slammed.connect(_on_slammed)
	GameState.coins_changed.connect(_refresh_hud)
	GameState.upgrade_changed.connect(_refresh_shop)
	_refresh_hud(GameState.coins)
	_refresh_shop()
	_start.visible = true
	_shop.visible = false
	_result.visible = false
	_hint.text = "点屏幕任意处开始"
	$HUD/Start/Panel/VBox/StartButton.pressed.connect(_on_start_pressed)
	_start.gui_input.connect(_on_start_gui_input)


func _input(event: InputEvent) -> void:
	if not _is_press(event):
		return
	if _result.visible:
		return
	if not _playing:
		start_game()
		get_viewport().set_input_as_handled()
		return
	if _shop.visible or _settling:
		return
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered is Button:
		return
	var at := get_global_mouse_position()
	if _wipe_mode:
		_do_wipe(at)
		get_viewport().set_input_as_handled()
		return
	_slipper.try_slam(at)
	get_viewport().set_input_as_handled()


func _is_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	return false


func _on_start_gui_input(event: InputEvent) -> void:
	if _is_press(event) and not _playing:
		start_game()


func start_game() -> void:
	if _playing:
		return
	_playing = true
	_start.visible = false
	_result.visible = false
	_begin_level()


func _begin_level() -> void:
	_settling = false
	_combo = 0
	_wipes = 2
	_wipe_mode = false
	_eat_cd = maxf(1.6, 3.0 - float(_level) * 0.18)
	_wipe_btn.text = "擦一擦 x%d" % _wipes
	_clear_group(_candies)
	_clear_group(_roaches)
	_clear_group(_stains)
	_spawn_candies()
	_roaches_left = _roach_goal()
	for i in _roaches_left:
		_spawn_roach()
	_update_goals()
	_hint.text = "第%d关  拍死蟑螂，别把糖拍脏、拍飞" % _level


func _process(delta: float) -> void:
	if not _playing:
		return
	_combo_time -= delta
	if _combo_time <= 0.0:
		_combo = 0
		_combo_label.text = ""
	_eat_cd -= delta
	if not _settling and _eat_cd <= 0.0 and _alive_roaches() > 0:
		_roach_steal()
		_eat_cd = maxf(1.6, 3.0 - float(_level) * 0.18)
	_update_goals()


func _keep_need() -> float:
	return clampf(0.55 + float(_level - 1) * 0.03, 0.55, 0.72)


func _goo_max() -> float:
	return clampf(0.16 - float(_level - 1) * 0.015, 0.08, 0.16)


func _edible_need() -> int:
	return int(round(float(CANDY_COUNT) * clampf(0.48 - float(_level - 1) * 0.02, 0.36, 0.48)))


func _roach_goal() -> int:
	return mini(3 + _level + GameState.spawn_level, 10)


func _build_bowl() -> void:
	_add_wall(Vector2(58, 1088), Vector2(36, 220))
	_add_wall(Vector2(662, 1088), Vector2(36, 220))
	_add_wall(Vector2(360, 1218), Vector2(700, 56))


func _add_wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	body.position = pos
	body.add_child(cs)
	_world.add_child(body)


func _spawn_candies() -> void:
	for i in CANDY_COUNT:
		var candy: RigidBody2D = CANDY_SCENE.instantiate()
		var color: Color = ProcArt.CANDY_COLORS[i % ProcArt.CANDY_COLORS.size()]
		var radius := randf_range(15.0, 23.0)
		candy.setup(color, radius)
		candy.position = Vector2(
			randf_range(_pile.position.x, _pile.end.x),
			randf_range(_pile.position.y - 40.0, _pile.end.y - 20.0)
		)
		candy.rotation = randf() * TAU
		_candies.add_child(candy)


func _spawn_roach() -> void:
	var roach: Area2D = ROACH_SCENE.instantiate()
	var is_golden := randf() < 0.08
	roach.setup(_pile, is_golden)
	roach.position = Vector2(
		randf_range(_pile.position.x + 24.0, _pile.end.x - 24.0),
		randf_range(_pile.position.y + 20.0, _pile.end.y - 20.0)
	)
	roach.squished.connect(_on_roach_squished)
	_roaches.add_child(roach)


func _on_slammed(at: Vector2, radius: float) -> void:
	var hit_any := false
	for child in _roaches.get_children():
		if not child.has_method("smash") or not child.alive:
			continue
		if child.global_position.distance_to(at) <= radius + 22.0:
			var smear_r := 42.0 if child.is_exposed() else 78.0
			if child.golden:
				smear_r *= 1.15
			child.smash()
			_smear_candies(child.global_position, smear_r)
			hit_any = true
	_blast_candies(at, 360.0 if hit_any else 280.0)
	if not hit_any:
		_hint.text = "拍空了。等它探头，或用透视再拍"


func _on_roach_squished(_roach: Node2D, golden: bool, pos: Vector2) -> void:
	_combo += 1
	_combo_time = 1.7
	if _combo > GameState.best_combo:
		GameState.best_combo = _combo
	var gain := (12 if golden else 3) * mini(_combo, 8)
	if _roach.has_method("is_exposed") and _roach.is_exposed():
		gain += 8
		_hint.text = "探头时拍中，糖比较干净  +%d" % gain
	else:
		_hint.text = "糖堆里拍碎了，脏浆溅出来了  +%d" % gain
	GameState.add_coins(gain)
	_combo_label.text = "连击 x%d" % _combo
	_spawn_stain(pos, golden)
	_roaches_left = maxi(_roaches_left - 1, 0)
	_float_text(pos, "+%d" % gain)
	if _alive_roaches() == 0:
		_start_settle()


func _alive_roaches() -> int:
	var n := 0
	for child in _roaches.get_children():
		if child.has_method("smash") and child.alive:
			n += 1
	return n


func _start_settle() -> void:
	if _settling:
		return
	_settling = true
	_hint.text = "结算中…"
	await get_tree().create_timer(0.85).timeout
	_finish_level()


func _finish_level() -> void:
	var keep := _keep_ratio()
	var goo := _cover_ratio()
	var edible := _edible_count()
	var keep_ok := keep >= _keep_need()
	var goo_ok := goo <= _goo_max()
	var edible_ok := edible >= _edible_need()
	_result.visible = true
	var cont := $HUD/Result/Panel/VBox/ContinueBtn as Button
	if keep_ok and goo_ok and edible_ok:
		_result_title.text = "过关！"
		_result_desc.text = "盘上剩余 %d%%（需≥%d%%）\n沾浆污染 %d%%（要≤%d%%）\n可食用 %d 颗（需≥%d）" % [
			roundi(keep * 100.0), roundi(_keep_need() * 100.0),
			roundi(goo * 100.0), roundi(_goo_max() * 100.0),
			edible, _edible_need()
		]
		GameState.add_coins(20 + _level * 8)
		_level += 1
		cont.text = "下一关"
	else:
		_result_title.text = "没过关"
		var why := ""
		if not keep_ok:
			why += "珠子飞出去太多。\n"
		if not goo_ok:
			why += "蟑螂浆溅到糖上太多，不能吃了。等它探头再拍，或用纸巾擦。\n"
		if not edible_ok:
			why += "可吃的糖不够。蟑螂会偷吃，动作要快。"
		_result_desc.text = "盘上 %d%% / ≥%d%%\n沾浆 %d%% / ≤%d%%\n可食用 %d / ≥%d\n%s" % [
			roundi(keep * 100.0), roundi(_keep_need() * 100.0),
			roundi(goo * 100.0), roundi(_goo_max() * 100.0),
			edible, _edible_need(),
			why
		]
		cont.text = "再试一次"
	_settling = false
	_playing = false


func _blast_candies(at: Vector2, force: float) -> void:
	for child in _candies.get_children():
		var rb := child as RigidBody2D
		if rb == null:
			continue
		var offset := rb.global_position - at
		var dist := offset.length()
		if dist > 108.0:
			continue
		var falloff := 1.0 - dist / 108.0
		var dir := offset.normalized() if dist > 1.0 else Vector2.UP
		dir = (dir + Vector2(0, -0.28)).normalized()
		rb.sleeping = false
		rb.apply_central_impulse(dir * force * falloff * randf_range(0.75, 1.05))
		rb.apply_torque_impulse(randf_range(-140.0, 140.0) * falloff)


func _smear_candies(pos: Vector2, radius: float) -> void:
	for child in _candies.get_children():
		if not child.has_method("add_goo"):
			continue
		var dist: float = child.global_position.distance_to(pos)
		if dist > radius:
			continue
		var amt := (1.0 - dist / radius) * 0.72
		child.add_goo(amt)


func _spawn_stain(pos: Vector2, golden: bool) -> void:
	for i in 5:
		var stain := Polygon2D.new()
		var s := randf_range(10.0, 26.0)
		stain.polygon = PackedVector2Array([
			Vector2(-s, -s * 0.4), Vector2(-s * 0.2, -s), Vector2(s * 0.7, -s * 0.5),
			Vector2(s, s * 0.2), Vector2(s * 0.3, s), Vector2(-s * 0.6, s * 0.6),
		])
		stain.color = Color("5D2E1F", 0.72) if not golden else Color("C62828", 0.7)
		stain.global_position = pos + Vector2(randf_range(-28, 28), randf_range(-18, 18))
		stain.rotation = randf() * TAU
		stain.z_index = 3
		_stains.add_child(stain)


func _keep_ratio() -> float:
	var on_plate := 0
	for child in _candies.get_children():
		if _plate.has_point(child.global_position):
			on_plate += 1
	return float(on_plate) / float(CANDY_COUNT)


func _cover_ratio() -> float:
	var goo_area := 0.0
	var total := 0.0
	for child in _candies.get_children():
		if not _plate.has_point(child.global_position):
			continue
		if child.has_method("disk_area"):
			total += child.disk_area()
			goo_area += child.goo_area()
	if total <= 0.0:
		return 0.0
	return goo_area / total


func _edible_count() -> int:
	var n := 0
	for child in _candies.get_children():
		if not _plate.has_point(child.global_position):
			continue
		if child.has_method("is_edible") and child.is_edible():
			n += 1
	return n


func _update_goals() -> void:
	var keep := _keep_ratio()
	var goo := _cover_ratio()
	var edible := _edible_count()
	_keep_label.text = "盘上剩余 %d%%  要≥%d%%" % [roundi(keep * 100.0), roundi(_keep_need() * 100.0)]
	_cover_label.text = "沾浆污染 %d%%  要≤%d%%" % [roundi(goo * 100.0), roundi(_goo_max() * 100.0)]
	_eat_label.text = "可食用 %d颗  要≥%d颗" % [edible, _edible_need()]
	_keep_label.modulate = Color("2E7D32") if keep >= _keep_need() else Color("C62828")
	_cover_label.modulate = Color("2E7D32") if goo <= _goo_max() else Color("C62828")
	_eat_label.modulate = Color("2E7D32") if edible >= _edible_need() else Color("C62828")


func _float_text(pos: Vector2, text: String) -> void:
	var lab := Label.new()
	lab.text = text
	lab.position = pos + Vector2(-20, -40)
	lab.add_theme_font_size_override("font_size", 28)
	lab.add_theme_color_override("font_color", Color("FFF59D"))
	_world.add_child(lab)
	var tw := create_tween()
	tw.tween_property(lab, "position:y", lab.position.y - 50, 0.45)
	tw.parallel().tween_property(lab, "modulate:a", 0.0, 0.45)
	tw.tween_callback(lab.queue_free)


func _clear_group(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _refresh_hud(value: int) -> void:
	_coin_label.text = "金币  %d" % value


func _refresh_shop() -> void:
	if GameState.slipper_level >= GameState.SLIPPER_COSTS.size():
		_btn_slipper.text = "更大拖鞋  已满级"
		_btn_slipper.disabled = true
	else:
		_btn_slipper.disabled = false
		_btn_slipper.text = "更大拖鞋  %d金币" % GameState.SLIPPER_COSTS[GameState.slipper_level]
	if GameState.spawn_level >= GameState.SPAWN_COSTS.size():
		_btn_spawn.text = "蟑螂更多  已满级"
		_btn_spawn.disabled = true
	else:
		_btn_spawn.disabled = false
		_btn_spawn.text = "蟑螂更多  %d金币" % GameState.SPAWN_COSTS[GameState.spawn_level]
	if GameState.xray:
		_btn_xray.text = "蟑螂发光  已购买"
		_btn_xray.disabled = true
	else:
		_btn_xray.disabled = false
		_btn_xray.text = "蟑螂发光  %d金币" % GameState.XRAY_COST


func _do_wipe(at: Vector2) -> void:
	_wipe_mode = false
	if _wipes <= 0:
		return
	_wipes -= 1
	_wipe_btn.text = "擦一擦 x%d" % _wipes
	var wiped := 0
	for child in _candies.get_children():
		if not child.has_method("wipe_goo"):
			continue
		if child.global_position.distance_to(at) > 95.0:
			continue
		child.wipe_goo(0.55)
		wiped += 1
	for stain in _stains.get_children():
		if stain.global_position.distance_to(at) < 95.0:
			stain.queue_free()
	_hint.text = "擦掉一块脏浆" if wiped > 0 else "这里没什么脏东西"
	_update_goals()


func _roach_steal() -> void:
	var eater: Node2D = null
	for child in _roaches.get_children():
		if child.has_method("smash") and child.alive:
			eater = child
			break
	if eater == null:
		return
	var victim: Node2D = null
	var best := 9999.0
	for candy in _candies.get_children():
		if not _plate.has_point(candy.global_position):
			continue
		var d: float = candy.global_position.distance_to(eater.global_position)
		if d < best:
			best = d
			victim = candy
	if victim == null:
		return
	_float_text(victim.global_position, "被偷吃")
	victim.queue_free()
	_hint.text = "蟑螂在偷吃糖！快拍"


func _on_start_pressed() -> void:
	start_game()


func _on_wipe_pressed() -> void:
	if not _playing or _settling:
		return
	if _wipes <= 0:
		_hint.text = "纸巾用完了"
		return
	_wipe_mode = true
	_hint.text = "点糖堆，把脏浆擦掉"


func _on_result_continue() -> void:
	_result.visible = false
	start_game()


func _on_shop_pressed() -> void:
	_shop.visible = not _shop.visible


func _on_buy_slipper() -> void:
	if not GameState.try_buy_slipper():
		_hint.text = "金币不够"
	else:
		_hint.text = "拖鞋变大了！"


func _on_buy_spawn() -> void:
	if not GameState.try_buy_spawn():
		_hint.text = "金币不够"
	else:
		_hint.text = "这一关蟑螂会更多"


func _on_buy_xray() -> void:
	if not GameState.try_buy_xray():
		_hint.text = "金币不够"
	else:
		_hint.text = "能透过糖堆看到蟑螂"
		for child in _roaches.get_children():
			if child.has_method("_apply_xray"):
				child._apply_xray()
