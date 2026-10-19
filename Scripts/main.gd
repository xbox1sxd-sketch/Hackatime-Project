extends Node2D


var asteroid_scene = preload("res://Scenes/asteriod.tscn")

func _ready():
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(spawn_asteroid)
	add_child(timer)
	
func spawn_asteroid():
	var asteroid = asteroid_scene.instantiate()
	var screen = get_viewport_rect().size
	asteroid.position = Vector2(randf_range(40, screen.x - 40), -40)
	add_child(asteroid)
