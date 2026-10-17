class_name ShiftBudget
extends RefCounted

var day: int = 1
var modifier: String = "normal"
var modifier_name: String = "普通夜班"
var duration: float = 108.0
var interval: float = 10.2
var concurrent: int = 2
var ingredients: int = 1
var price_bonus: int = 0
var price_mul: float = 1.0
var patience: float = 45.0
var thief_chance: float = 0.29
var thief_time: float = 11.6
var disguise_bonus: int = 0
var fine_mul: float = 1.0
var roach_count: int = 1
var roach_interval: float = 8.8
var soil_seconds: float = 0.0
var stock: int = -1
var shortage: bool = false
var rinse: bool = false
var rent: int = 44
var wash_time: float = 1.8
var restock_cost: int = 9
var restock_time: float = 1.5
var rinse_time: float = 1.2
var cup_spoil: float = 2.5
var rng := RandomNumberGenerator.new()


static func roll(day: int, last_rating: float, tight_streak: int) -> ShiftBudget:
	var shift := ShiftBudget.new()
	shift.day = day
	shift.rng.seed = day
	shift.duration = clampf(100.0 + 8.0 * float(day), 100.0, 240.0)
	shift.interval = maxf(4.2, 10.5 - 0.35 * float(day))
	shift.concurrent = clampi(2 + int(float(day) / 3.0), 2, 5)
	shift.ingredients = 1 if day < 2 else clampi(1 + int(float(day - 1) / 4.0), 1, 4)
	shift.price_bonus = int(float(day) / 5.0) * 2
	shift.patience = maxf(18.0, round(46.0 - 1.1 * float(day)))
	shift.thief_chance = minf(0.7, 0.25 + 0.04 * float(day))
	shift.thief_time = maxf(6.0, 12.0 - 0.4 * float(day))
	shift.roach_count = clampi(1 + int(float(day) / 4.0), 1, 4)
	shift.roach_interval = maxf(4.0, 9.0 - 0.25 * float(day))
	shift.soil_seconds = 0.0 if day < 3 else maxf(1.1, 1.8 - 0.05 * float(day))
	shift.stock = -1 if day < 6 else maxi(4, 14 - day)
	shift.rinse = day >= 8
	shift.rent = int(round(30.0 + 14.0 * pow(float(day), 0.85)))
	shift.restock_cost = 8 + day
	var force_easy := last_rating < 3.0
	var force_regular := tight_streak >= 2 and day >= 4
	if force_regular:
		shift.modifier = "regular"
	elif force_easy:
		if day >= 4 and shift.rng.randi_range(0, 1) == 0:
			shift.modifier = "regular"
		else:
			shift.modifier = "normal"
	else:
		shift.modifier = shift._pick_modifier()
	shift._apply_modifier()
	if force_easy:
		shift.roach_count = maxi(shift.roach_count - 1, 0)
	shift.modifier_name = shift._modifier_label()
	return shift


func _pick_modifier() -> String:
	var ids: Array[String] = ["normal"]
	var weights: Array[int] = [10]
	if day >= 2:
		ids.append("rush")
		weights.append(4)
	if day >= 3:
		ids.append("picky")
		weights.append(3)
		ids.append("vermin")
		weights.append(4)
	if day >= 4:
		ids.append("regular")
		weights.append(2)
		ids.append("audit")
		weights.append(3)
	if day >= 5:
		ids.append("rain")
		weights.append(2)
	if day >= 6:
		ids.append("shortage")
		weights.append(3)
	var total := 0
	for weight in weights:
		total += weight
	var roll := rng.randi_range(1, total)
	var cursor := 0
	for i in ids.size():
		cursor += weights[i]
		if roll <= cursor:
			return ids[i]
	return "normal"


func _apply_modifier() -> void:
	match modifier:
		"rush":
			interval *= 0.75
			patience *= 1.15
		"picky":
			ingredients = mini(ingredients + 1, 4)
			price_mul = 1.25
		"vermin":
			roach_count = mini(roach_count + 1, 4)
			if soil_seconds > 0.0:
				soil_seconds /= 1.4
		"regular":
			thief_chance = 0.0
			patience *= 1.3
			rent = int(round(float(rent) * 0.85))
		"audit":
			disguise_bonus = 1
			fine_mul = 1.5
		"rain":
			duration *= 0.8
			concurrent = mini(concurrent + 1, 5)
		"shortage":
			shortage = true


func _modifier_label() -> String:
	match modifier:
		"rush":
			return "赶单"
		"picky":
			return "挑嘴"
		"vermin":
			return "虫害"
		"regular":
			return "熟客夜"
		"audit":
			return "稽查"
		"rain":
			return "暴雨客流"
		"shortage":
			return "断货"
		_:
			return "普通夜班"
