extends Area2D

var bullet_scene = preload("res://Scenes/Bullet.tscn")
var margin = 32
var can_shoot = true
var bullet_count = 1
var spread = 0.15
var bomb_ready = false
var bomb_cooldown = 12.0
var bomb_radius = 300
var bomb_damage = 6
var crit_multiplier = 2.0
var base_fire_delay = 0.4
var base_bullet_damage = 2
var base_crit_chance = 0.1
var fire_delay = 0.4
var bullet_damage = 2
var crit_chance = 0.1
@onready var sprite = $AnimatedSprite2D



func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	global_position = get_viewport_rect().size / 2
	recalculate()
	start_bomb_charge()

func recalculate():
	fire_delay = max(base_fire_delay, 0.05)
	bullet_damage = base_bullet_damage
	crit_chance = clamp(base_crit_chance, 0.0, 1.0)
	
func apply_ship_color(c):
	sprite.self_modulate
	
func start_bomb_charge():
	await get_tree().create_timer(bomb_cooldown, true, false, true).timeout
	bomb_ready = true
	get_parent().update_ui()



func _process(_delta):
	if get_parent().menu_open: return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		shoot()

func _input(event):
	if get_tree().paused: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var screen = get_viewport_rect().size
		global_position += event.relative
		global_position.x = clamp(global_position.x, margin, screen.x - margin)
		global_position.y = clamp(global_position.y, margin, screen.y - margin)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not get_parent().menu_open:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		use_bomb()


func use_bomb():
	if not bomb_ready or get_parent().game_over:
		return
	bomb_ready = false
	get_parent().update_ui()
	var dmg = bomb_damage + bullet_damage * 2
	for a in get_tree().get_nodes_in_group("asteroids"):
		if a.is_queued_for_deletion():
			continue
		if a.global_position.distance_to(global_position) <= bomb_radius:
			a.take_hit(dmg)
	make_blast_ring()
	get_parent().play_sound(get_parent().boom_sound)
	get_parent().shake(25.0, 0.4)
	start_bomb_charge()



func make_blast_ring():
	var ring = CPUParticles2D.new()
	ring.position = global_position
	ring.one_shot = true
	ring.explosiveness = 1.0
	ring.amount = 60
	ring.lifetime = 0.4
	ring.spread = 180
	ring.gravity = Vector2.ZERO
	ring.initial_velocity_min = 650
	ring.initial_velocity_max = 750
	ring.scale_amount_min = 4
	ring.scale_amount_max = 6
	ring.color = Color.CYAN
	ring.finished.connect(ring.queue_free)
	get_parent().add_child(ring)
		
		
func make_muzzle_flash(pos):
	var flash = CPUParticles2D.new()
	flash.one_shot = true
	flash.explosiveness = 1.0
	flash.amount = 6
	flash.lifetime = 0.15
	flash.direction = Vector2(0, -1) 
	flash.spread = 25
	flash.gravity = Vector2.ZERO
	flash.initial_velocity_min = 150
	flash.initial_velocity_max = 250
	flash.scale_amount_min = 2
	flash.scale_amount_max = 4
	flash.color = Color.CYAN
	flash.emitting = true
	flash.finished.connect(flash.queue_free)
	get_parent().add_child(flash)
	flash.global_position = pos
	
	
func shoot():
	if get_tree().paused:
		return
	if get_parent().game_over:
		return
	if not can_shoot:
		return
	can_shoot = false
	get_parent().play_sound(get_parent().shoot_sound)
	var muzzle_pos = global_position + Vector2(0,-40)
	make_muzzle_flash(muzzle_pos)
	for i in bullet_count:
		var bullet = bullet_scene.instantiate()
		bullet.damage = bullet_damage
		var offset = ( i - (bullet_count - 1)/ 2.0) * spread
		get_parent().add_child(bullet)
		bullet.global_position = global_position + Vector2(0, -40)
		bullet.global_rotation = -PI / 2 + offset
	await get_tree().create_timer(fire_delay, true, false, true).timeout
	can_shoot = true
