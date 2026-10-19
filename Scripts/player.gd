extends Node2D

var bullet_scene = preload("res://Scenes/Bullet.tscn")
var margin = 32
var fire_delay = 0.4
var can_shoot = true

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
	print("shoot at ", global_position)
	if not can_shoot:
		return
	can_shoot = false
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position + Vector2(0, -40)
	bullet.global_rotation = -PI / 2
	get_parent().add_child(bullet)
	await get_tree().create_timer(fire_delay).timeout
	can_shoot = true

	if get_parent().game_over:
		return
