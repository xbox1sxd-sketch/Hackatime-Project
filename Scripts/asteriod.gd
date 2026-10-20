extends Area2D

var spin = 0.0
var size = 1.0
var health = 1
var damage = 1
var value = 5
var speed = 150
var tint = Color.WHITE
func _ready():
	add_to_group("asteroids")
	scale = Vector2.ONE * size
	modulate = tint
	spin = randf_range(-2.0, 2.0)
	area_entered.connect(_on_area_entered)
	
func _process(delta):
	rotation += spin * delta
	position.y += speed * delta
	if position.y > 700:
		get_parent().take_damage(damage)
		queue_free()
		
func _on_area_entered(area):
	if is_queued_for_deletion():
		return
	if area.is_in_group("bullets"):
		area.queue_free()
		take_hit(area.damage)
	elif area.is_in_group("player"):
		get_parent().take_damage(damage)
		get_parent().add_money(int(value/2))
		die(true)

func take_hit(amount):
	health -= amount
	if health <= 0:
		die(true)
	else:
		on_hit()

func on_hit():
	modulate = Color(2, 2, 2)
	create_tween().tween_property(self, "modulate", tint, 0.1)

func die(killed_by_player):
	if killed_by_player:
		get_parent().add_money(value)
		get_parent().play_sound(get_parent().boom_sound)
	make_explosion()
	queue_free()
	
func make_explosion():
	var boom = CPUParticles2D.new()
	boom.position = position
	boom.one_shot = true
	boom.explosiveness = 1.0
	boom.amount = int(15 * size)
	boom.lifetime = 0.5
	boom.spread = 180
	boom.gravity = Vector2.ZERO
	boom.initial_velocity_min = 80
	boom.initial_velocity_max = 200
	boom.scale_amount_min = 3
	boom.scale_amount_max = 6
	boom.color = tint
	boom.finished.connect(boom.queue_free)
	get_parent().add_child(boom)
