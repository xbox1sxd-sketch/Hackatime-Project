extends Area2D

var spin = 0.0
var size = 1.0
var health = 1
var damage = 1
var value = 5
var speed = 150
var splits_left = 0
var drift = 0.0
var start_health = 1
var tint = Color.WHITE
var is_boss = false


func _ready():
	add_to_group("asteroids")
	scale = Vector2.ONE * size
	modulate = tint
	spin = randf_range(-2.0, 2.0)
	area_entered.connect(_on_area_entered)
	start_health = health
	
func _process(delta):
	rotation += spin * delta
	position.x = clamp(position.x + drift * delta, 30, get_viewport_rect().size.x - 30)
	position.y += speed * delta
	if position.y > get_viewport_rect().size.y + 50:
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
		if is_boss:
			return
		get_parent().add_money(int(value * 0.5))
		get_parent().play_sound(get_parent().boom_sound)
		die(false)


func take_hit(amount):
	health -= amount
	if health <= 0:
		split()
		die(true)
	else:
		on_hit()

func split():
	if splits_left <= 0:
		return
	var main = get_parent()
	for i in 2:
		var kid = main.asteroid_scene.instantiate()
		kid.tint = tint
		kid.size = size * 0.7
		kid.health = max(1, int(start_health * 0.4))
		kid.damage = max(1, damage - 1)
		kid.speed = speed * 1.15
		kid.value = max(1, int(value * 0.4))
		kid.splits_left = splits_left - 1
		kid.drift = -80 + i * 160
		main.add_child(kid)
		kid.position = position + Vector2(-25 + i * 50, 0)

func on_hit():
	modulate = Color(2, 2, 2)
	create_tween().tween_property(self, "modulate", tint, 0.1)

func die(killed_by_player):
	if killed_by_player:
		if is_boss:
			get_parent().boss_reward()
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
