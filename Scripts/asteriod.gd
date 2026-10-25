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
		var hit_pos = area.global_position
		area.queue_free()
		take_hit(area.damage, hit_pos)
	elif area.is_in_group("player"):
		get_parent().take_damage(damage)
		if is_boss:
			return
		get_parent().add_money(int(value * 0.5))
		get_parent().play_sound(get_parent().boom_sound)
		die(false)


func make_sparks(pos):
	var sparks = CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 8
	sparks.lifetime = 0.2
	sparks.spread = 180
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 80
	sparks.initial_velocity_max = 160
	sparks.scale_amount_min = 1
	sparks.scale_amount_max = 2.5
	sparks.color = Color.WHITE
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)
	get_parent().add_child(sparks)
	sparks.global_position = pos


func show_damage_number(amount, is_crit):
	var label = Label.new()
	if is_crit:
		label.text = "-" + str(amount)
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		label.text = "-" + str(amount)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.YELLOW)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.z_index = 100
	get_parent().add_child(label)
	var screen = get_viewport_rect().size
	var offset_x = 40
	if global_position.x > screen.x - 100:
		offset_x = -40
	label.global_position = global_position + Vector2(offset_x, randf_range(-15, 15))
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:x", label.global_position.x + (offset_x * 0.5), 0.3)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.finished.connect(label.queue_free)


func take_hit(amount, hit_pos = null):
	if health <= 0:
		return
	var is_crit = false
	if randf() < get_parent().player.crit_chance:
		amount = int(amount * get_parent().player.crit_multiplier)
		is_crit = true
	health -= amount
	if is_boss:
		get_parent().update_boss_health(health)
	show_damage_number(amount, is_crit)
	
	if health <= 0:
		split()
		die(true)
	else:
		if hit_pos != null:
			make_sparks(hit_pos)
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
		kid.position = position + Vector2(-25 + i * 50, 0)
		main.call_deferred("add_child", kid)

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
