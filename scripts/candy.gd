extends RigidBody2D

var candy_color: Color = Color.WHITE
var radius: float = 20.0
var goo: float = 0.0


func setup(color: Color, r: float) -> void:
	candy_color = color
	radius = r
	var sprite := $Sprite2D as Sprite2D
	sprite.texture = ProcArt.candy_texture(color)
	var target := r * 2.2
	var tex_w := float(sprite.texture.get_width())
	sprite.scale = Vector2.ONE * (target / tex_w)
	var goo_sprite := $Goo as Sprite2D
	goo_sprite.texture = sprite.texture
	goo_sprite.scale = sprite.scale
	goo_sprite.modulate = Color(0.32, 0.14, 0.07, 0.0)
	var shape := CircleShape2D.new()
	shape.radius = r
	$CollisionShape2D.shape = shape
	mass = 0.28
	gravity_scale = 1.2
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.16
	mat.friction = 0.62
	physics_material_override = mat


func add_goo(amount: float) -> void:
	goo = minf(goo + amount, 1.0)
	$Goo.modulate.a = goo * 0.82


func wipe_goo(amount: float) -> void:
	goo = maxf(goo - amount, 0.0)
	$Goo.modulate.a = goo * 0.82


func is_edible() -> bool:
	return goo < 0.18


func goo_area() -> float:
	return PI * radius * radius * goo


func disk_area() -> float:
	return PI * radius * radius
