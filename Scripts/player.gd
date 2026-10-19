extends Node2D

var bullet_scene = preload("res://Scenes/Bullet.tscn")
var margin = 32
var fire_delay = 0.4
var can_shoot = true
var bullet_count = 1
var spread = 0.15

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	global_position = get_viewport_rect().size / 2

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var screen = get_viewport_rect().size
		global_position += event.relative
		global_position.x = clamp(global_position.x, margin, screen.x - margin)
		global_position.y = clamp(global_position.y, margin, screen.y - margin)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			shoot()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func shoot():
	if get_parent().game_over:
		return
	if not can_shoot:
		return
	can_shoot = false
	for i in bullet_count:
		var bullet = bullet_scene.instantiate()
		var offset = ( i - (bullet_count - 1)/ 2.0) * spread
		bullet.global_position = global_position + Vector2(0, -40)
		bullet.global_rotation = -PI / 2 + offset
		get_parent().add_child(bullet)
	await get_tree().create_timer(fire_delay).timeout
	can_shoot = true

	if get_parent().game_over:
		return
