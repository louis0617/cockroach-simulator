class_name Order
extends RefCounted

var order_id: String = ""
var platform: String = "self"
var display_name: String = ""
var ingredients: Array[String] = []
var shakes: int = 0
var shake_required: bool = false
var time_limit: float = 40.0
var time_left: float = 40.0
var status: String = "pending"
var price: int = 0


func platform_label() -> String:
	match platform:
		"jisong":
			return "急送达"
		"ebu":
			return "饿不饿"
		_:
			return "到店喊"


func value() -> int:
	if price > 0:
		return price
	return 12 + ingredients.size() * 4


func recipe_key() -> String:
	var names: Array[String] = ingredients.duplicate()
	names.sort()
	return "%s#s%d" % ["+".join(names), shakes]


func describe() -> String:
	var text := "、".join(ingredients)
	text += "、加水"
	if shakes > 0:
		text += "、摇%d次" % shakes
	return text
