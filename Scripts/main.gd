extends Node2D


var asteroid_scene = preload("res://Scenes/asteriod.tscn")
var money = 0
var fire_rate_cost = 10
var health = 5
var game_over = false
var spawn_timer
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var player = $Player

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.0
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(spawn_asteroid)
	add_child(spawn_timer)
	update_ui()

func spawn_asteroid():
	var asteroid = asteroid_scene.instantiate()
	var screen = get_viewport_rect().size
	asteroid.position = Vector2(randf_range(40, screen.x - 40), -40)
	add_child(asteroid)

func add_money(amount):
	money += amount 
	update_ui()

func take_damage(amount):
	if game_over:
		return
	health -= amount
	if health <= 0:
		health = 0
		game_over = true
		spawn_timer.stop()
	update_ui()

func update_ui():
	if game_over:
		money_label.text = "GAME OVER \nMoney: " + str(money) + "\n Press R to restart"
	else:
		money_label.text = "health: " + str(health) + "\nmoney: " + str(money) + "\n [1] Faster Fire (cost " + str(fire_rate_cost) + ")"

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and game_over:
			get_tree().reload_current_scene()
		if event.keycode == KEY_1 and not game_over:
			buy_fire_rate()



func buy_fire_rate():
	if money >= fire_rate_cost:
		money -= fire_rate_cost
		player.fire_delay = max(0.1, player.fire_delay * 0.85)
		fire_rate_cost = int(fire_rate_cost * 1.5)
		update_ui()
