class_name ShopColors
extends RefCounted

const MAP := {
	"爆珠": Color("5D4037"),
	"奶霜": Color("FFF8E1"),
	"冷萃": Color("6D4C41"),
	"芋圆": Color("7E57C2"),
	"烤布蕾": Color("F9A825"),
	"碎冰": Color("B3E5FC"),
	"焙茶": Color("8D6E63"),
	"芝麻糊": Color("424242"),
	"芒果泥": Color("FFB300"),
	"椰奶": Color("FFF3E0"),
	"黑糖碎": Color("4E342E"),
	"厚乳": Color("FFE0B2"),
}


static func of(item: String) -> Color:
	if MAP.has(item):
		return MAP[item]
	return Color("BCAAA4")
