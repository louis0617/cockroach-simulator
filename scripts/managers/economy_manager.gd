extends Node

signal economy_changed

var money: int = 0
var rating: float = 5.0
var good_reviews: int = 0
var bad_reviews: int = 0
var day_revenue: int = 0
var day_fine: int = 0
var day_stolen: int = 0
var day_restock: int = 0
var day_rent: int = 0
var day_good: int = 0
var day_bad: int = 0


func reset_for_new_day() -> void:
	day_revenue = 0
	day_fine = 0
	day_stolen = 0
	day_restock = 0
	day_rent = 0
	day_good = 0
	day_bad = 0
	economy_changed.emit()


func add_revenue(amount: int) -> void:
	money += amount
	day_revenue += amount
	economy_changed.emit()


func add_bonus(amount: int) -> void:
	money += amount
	day_revenue += amount
	economy_changed.emit()


func add_fine(amount: int) -> void:
	money -= amount
	day_fine += amount
	economy_changed.emit()


func add_stolen_loss(amount: int) -> void:
	money -= amount
	day_stolen += amount
	economy_changed.emit()


func add_restock(amount: int) -> void:
	money -= amount
	day_restock += amount
	economy_changed.emit()


func charge_rent(amount: int) -> void:
	money -= amount
	day_rent += amount
	economy_changed.emit()


func add_review(is_good: bool) -> void:
	if is_good:
		good_reviews += 1
		day_good += 1
	else:
		bad_reviews += 1
		day_bad += 1
	_recalc_rating()
	economy_changed.emit()


func summary() -> Dictionary:
	return {
		"revenue": day_revenue,
		"platform_fine": day_fine,
		"stolen_loss": day_stolen,
		"restock": day_restock,
		"rent": day_rent,
		"good_reviews": day_good,
		"bad_reviews": day_bad,
		"rating_after": rating,
		"money": money,
	}


func _recalc_rating() -> void:
	var total := good_reviews + bad_reviews
	if total <= 0:
		rating = 5.0
		return
	rating = clampf(5.0 - float(bad_reviews) / float(total) * 2.5, 0.0, 5.0)
