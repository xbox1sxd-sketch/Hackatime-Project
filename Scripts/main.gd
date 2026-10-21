extends Node2D

var shoot_sound = preload("res://Assets/shoot.wav")
var boom_sound = preload("res://Assets/boom.wav")
var hurt_sound = preload("res://Assets/hurt.wav")
var asteroid_scene = preload("res://Scenes/asteriod.tscn")
var money = 0
var fire_rate_cost = 60
var health = 20
var game_over = false
var spawn_timer
var wave = 0
var to_spawn = 0
var wave_active = false
var multishot_cost = 150
var repair_cost = 40
var max_health = 5
var boss_spawned = false
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var player = $Player
var damage_cost = 100
var best_wave = 0
var max_health_cost = 120
const save_path = "user://save.json"



func _ready():
	money_label.position = Vector2(20, 20)
	money_label.add_theme_font_size_override("font_size", 28)
	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(spawn_asteroid)
	add_child(spawn_timer)
	load_game()
	health = max_health
	start_next_wave()

func start_next_wave():
	boss_spawned = false
	wave += 1
	to_spawn = 4 + wave * 2
	wave_active = true
	spawn_timer.wait_time = max(0.3, 1.0 - wave * 0.05)
	spawn_timer.start()
	update_ui()

func spawn_boss():
	var boss = asteroid_scene.instantiate()
	boss.is_boss = true
	boss.tint = Color(0.658, 0.144, 0.704, 1.0)
	boss.size = 5.0
	boss.health = 60 + wave * 8
	boss.damage = 5
	boss.speed = 40
	boss.value = 50 + wave * 10
	boss.position = Vector2(get_viewport_rect().size.x/ 2, -150)
	add_child(boss)
	update_ui()

func spawn_asteroid():
	if game_over:
		return
	if wave % 5 == 0 and not boss_spawned:
		boss_spawned = true
		spawn_boss()
		return
	var asteroid = asteroid_scene.instantiate()
	var screen = get_viewport_rect().size
	var roll = randf()
	var big_chance = min(0.3, wave * 0.04)
	var medium_chance = min(0.4, wave * 0.1)
	if roll < big_chance:
		asteroid.tint = Color(0.6, 0.0, 0.13, 1.0)
		asteroid.size = 4.0
		asteroid.health = 5 + wave * 0.7
		asteroid.damage = 3 + floori(wave / 5.0)
		asteroid.splits_left = 1
		asteroid.speed = 100 + wave * 11
	elif roll < big_chance + medium_chance:
			asteroid.tint = Color(0.7, 0.5, 0.0, 1.0)
			asteroid.size = 3.4
			asteroid.health = 3 + wave * 0.6
			asteroid.damage = 2 + floori(wave / 5.0)
			asteroid.speed = 175 + wave * 12
	else:
		asteroid.tint = Color(0.773, 0.763, 0.003, 1.0) 
		asteroid.size = 2.5
		asteroid.health = 1 + wave * 0.5
		asteroid.damage = 1 + floori(wave / 5.0)
		asteroid.speed = 300 + wave * 22
	asteroid.value = int((2 + wave * 0.2) * asteroid.size * asteroid.size)
	asteroid.position = Vector2(randf_range(60, screen.x - 60), -60)
	add_child(asteroid)
	to_spawn -= 1
	if to_spawn <= 0:
		spawn_timer.stop()


func boss_reward():
	health = min(max_health, health + 3)
	update_ui()


func _process(_delta):
	if game_over or not wave_active:
		return
	if to_spawn <= 0 and get_tree().get_nodes_in_group("asteroids").size() == 0:
		wave_active = false
		best_wave = max(best_wave, wave)
		save_game()
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
	play_sound(hurt_sound)
	if health <= 0:
		health = 0
		game_over = true
		spawn_timer.stop()
		best_wave = max(best_wave, wave)
		save_game()
	update_ui()

func get_shop_text():
	var shop = "\n[1] Faster fire (" + str(fire_rate_cost) + ")"
	if player.bullet_count < 5:
		shop += "\n[2] Multi-shot (" + str(multishot_cost) + ")"
	else:
		shop += "\n[2] Multi-shot is MAX"
	if not game_over:
		shop += "\n[3] Repair +1 (" + str(repair_cost) + ")"
	shop += "\n[4] Damage +1 (" + str(damage_cost) + ")"
	if max_health < 15:
		shop += "\n[5] Max health +1 (" + str(max_health_cost) + ")"
	else:
		shop += "\n[5] Max health is MAX"
	return shop

func update_ui():
	if game_over:
		money_label.text = "GAME OVER\nYou reached wave " + str(wave) + "\nBest wave: " + str(best_wave) + "\nMoney: " + str(money) + "\n" + get_shop_text() + "\n\nPress R to restart"
	else:
		var status = "Wave " + str(wave)
		if wave % 5 == 0:
			status += " BOSS IS COMING"
		if not wave_active:
			status += "\nWAVE CLEARED! Next wave is coming"
		money_label.text = status + "\nHealth " + str(health) + "/" + str(max_health) + "\nMoney: " + str(money) + get_shop_text()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and game_over:
			get_tree().reload_current_scene()
		if event.keycode == KEY_1:
			buy_fire_rate()
		if event.keycode == KEY_2:
			buy_multishot()
		if event.keycode == KEY_3 and not game_over:
			buy_repair()
		if event.keycode == KEY_4:
			buy_damage()
		if event.keycode == KEY_5:
			buy_max_health()

func buy_damage():
	if money >= damage_cost:
		money -= damage_cost
		player.bullet_damage += 1
		damage_cost = int(damage_cost * 1.8)
		update_ui()
		save_game()

func buy_max_health():
	if max_health >= 15:
		return
	if money >= max_health_cost:
		money -= max_health_cost
		max_health += 1
		if not game_over:
			health += 1
		max_health_cost = int(max_health_cost * 1.6)
		update_ui()
		save_game()

func buy_multishot():
	if player.bullet_count >= 5:
		return
	if money >= multishot_cost:
		money -= multishot_cost
		player.bullet_count += 1
		multishot_cost = int(multishot_cost * 5)
		update_ui()
		save_game()

func buy_repair():
	if health >= max_health:
		return
	if money >= repair_cost:
		money -= repair_cost
		health += 1
		repair_cost = int(repair_cost * 1.3)
		update_ui()
		save_game()

func buy_fire_rate():
	if money >= fire_rate_cost:
		money -= fire_rate_cost
		player.fire_delay = max(0.1, player.fire_delay * 0.85)
		fire_rate_cost = int(fire_rate_cost * 2)
		update_ui()
		save_game()

func play_sound(stream):
	var p = AudioStreamPlayer.new()
	p.volume_db = -8
	p.stream = stream
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func save_game():
	var data = {
		"money": money,
		"best_wave": best_wave,
		"fire_delay": player.fire_delay,
		"fire_rate_cost": fire_rate_cost,
		"bullet_count": player.bullet_count,
		"multishot_cost": multishot_cost,
		"bullet_damage": player.bullet_damage,
		"damage_cost": damage_cost,
		"repair_cost": repair_cost,
		"max_health": max_health,
		"max_health_cost": max_health_cost
	}

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	
func load_game():
	if not FileAccess.file_exists(save_path):
		return
	var file = FileAccess.open(save_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		return
	money = int(data.get("money", 0))
	best_wave = int(data.get("best_wave", 0))
	player.fire_delay = float(data.get("fire_delay", 0.4))
	fire_rate_cost = int(data.get("fire_rate_cost", 10))
	player.bullet_count= int(data.get("bullet_count", 1))
	multishot_cost = int(data.get("multishot_cost", 25))
	player.bullet_damage = int(data.get("bullet_damage", 1))
	damage_cost = int(data.get("damage_cost", 40))
	repair_cost = int(data.get("repair_cost", 15))
	max_health = int(data.get("max_health", 5))
	max_health_cost = int(data.get("max_health_cost", 30))
	
