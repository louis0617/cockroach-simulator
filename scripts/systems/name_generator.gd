class_name NameGenerator
extends RefCounted

const HEADS: Array[String] = [
	"谎报糖度", "夜班续命", "摸鱼专供", "老板不在", "电梯狂摇",
	"口袋漏糖", "甜度报警", "散架前摇", "困兽出笼", "忘词之后",
	"加满再说", "反骨少冰", "加班冒泡", "偷偷双倍", "摇完就睡",
]
const CORES: Array[String] = [
	"爆珠", "奶霜", "冷萃", "芋圆", "烤布蕾", "碎冰",
	"焙茶", "芝麻糊", "芒果泥", "椰奶", "黑糖碎", "厚乳",
]
const TAILS: Array[String] = [
	"事故杯", "摇散号", "续命罐", "甜警报", "加班杯",
	"困兽罐", "漏糖号", "限定事故",
]
const GAGS: Array[String] = [
	"甜到报警", "摇到散架", "困成一滩", "冰多到吵架", "糖度超标",
]


static func generate(day: int, rng: RandomNumberGenerator = null) -> String:
	var count := clampi(2 + int(float(day) / 2.0), 2, 6)
	var parts: Array[String] = []
	parts.append(_pick(HEADS, parts, rng))
	var guard := 0
	while parts.size() < count - 1 and guard < 24:
		guard += 1
		var mid := _pick(CORES, parts, rng)
		if mid == "":
			break
		parts.append(mid)
	parts.append(_pick(TAILS, parts, rng))
	if day >= 2 and _roll(rng) < 0.55:
		var gag := _pick(GAGS, parts, rng)
		if gag != "":
			parts.insert(mini(1, parts.size()), gag)
	if day >= 4 and _roll(rng) < 0.45:
		var extra := _pick(GAGS, parts, rng)
		if extra != "":
			parts.append(extra)
	return "".join(parts)


static func _roll(rng: RandomNumberGenerator) -> float:
	if rng == null:
		return randf()
	return rng.randf()


static func _pick(pool: Array[String], used: Array[String], rng: RandomNumberGenerator = null) -> String:
	var start := randi() % pool.size() if rng == null else rng.randi() % pool.size()
	for i in pool.size():
		var word: String = pool[(start + i) % pool.size()]
		if not used.has(word):
			return word
	return ""
