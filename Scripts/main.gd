extends Node2D


var asteroid_scene = preload("res://Scenes/asteriod.tscn")
var money = 0
var fire_rate_cost = 10
var health = 5
var game_over = false
var spawn_timer
var wave = 0
var to_spawn = 0
var wave_active = false
var multishot_cost = 25
var repair_cost = 15
var max_health = 5
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var player = $Player

func _ready():
	money_label.position = Vector2(20, 20)
	money_label.add_theme_font_size_override("font_size", 28)
	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(spawn_asteroid)
	add_child(spawn_timer)
	start_next_wave()

func start_next_wave():
	wave += 1
	to_spawn = 4 + wave * 2
	wave_active = true
	spawn_timer.wait_time = max(0.3, 1.0 - wave * 0.05)
	spawn_timer.start()
	update_ui()
	

func spawn_asteroid():
	if game_over:
		return
	var asteroid = asteroid_scene.instantiate()
	var screen = get_viewport_rect().size
	asteroid.position = Vector2(randf_range(40, screen.x - 40), -40)
	asteroid.speed = 150 + wave * 15
	add_child(asteroid)
	to_spawn -= 1
	if to_spawn <= 0:
		spawn_timer.stop()

func _process(delta):
	if game_over or not wave_active:
		return
	if to_spawn <= 0 and get_tree().get_nodes_in_group("asteroids").size() == 0:
		wave_active = false
		update_ui()
		await get_tree().create_timer(3.0).timeout
		if not game_over:
			start_next_wave()

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
		money_label.text = "GAME OVER\nYou reached wave " + str(wave) + "\nMoney: " + str(money) + "\nPress R to restart"
	else:
		var status = "Wave " + str(wave)
		if not wave_active:
			status += "\nWAVE CLEARED! Next wave is coming"
		var shop = "\n[1] Faster fire (" + str(fire_rate_cost) + ")"
		if player.bullet_count < 5:
			shop += "\n[2] Multi-shot (" + str(multishot_cost) + ")"
		else:
			shop += "\n[2] Multi-shot is MAX"
		shop += "\n[3] Repair +1 (" + str(repair_cost) + ")"
		money_label.text = status + "\nHealth " + str(health) + "\nMoney: " + str(money) + shop

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and game_over:
			get_tree().reload_current_scene()
		if not game_over:
			if event.keycode == KEY_1 and not game_over:
				buy_fire_rate()
			if event.keycode == KEY_2:
				buy_multishot()
			if event.keycode == KEY_3:
				buy_repair()

func buy_multishot():
	if player.bullet_count >= 5:
		return
	if money >= multishot_cost:
		money -= multishot_cost
		player.bullet_count += 1
		multishot_cost = int(multishot_cost * 2)
		update_ui()
		
func buy_repair():
	if health >= max_health:
		return
	if money >= repair_cost:
		money -= repair_cost
		health += 1
		repair_cost = int(repair_cost * 1.3)
		update_ui()

func buy_fire_rate():
	if money >= fire_rate_cost:
		money -= fire_rate_cost
		player.fire_delay = max(0.1, player.fire_delay * 0.85)
		fire_rate_cost = int(fire_rate_cost * 1.5)
		update_ui()
