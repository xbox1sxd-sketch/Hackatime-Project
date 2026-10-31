extends Node2D
@onready var upgrade_sound = $CanvasLayer/UpgradeSound
@onready var firerate = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/FireRate
@onready var multishot = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/MultiShot
@onready var repair = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Repair
@onready var damage = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Damage
@onready var maxhealth = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/MaxHealth
@onready var crit = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Crit
@onready var pause_menu = $CanvasLayer/Pausemenu
@onready var camera = $Camera2D
@onready var upgrade_panel = $CanvasLayer/PanelContainer
@onready var upgrade_prompt = $CanvasLayer/UpgradeMenuPrompt
@onready var prestige: Button = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Prestige
@onready var ui_sound = $CanvasLayer/UISound
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var player = $Player
@onready var offline_btn = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/OfflineUpgrade
@onready var boss_health_bar = $CanvasLayer/BossHealthBar
@onready var bomb_cooldown = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/BombCooldown
@onready var bomb_damage = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/BombDamage
@onready var bomb_double = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/BombDouble
var combo = 1
var combo_timer
var shoot_sound = preload("res://Assets/shoot.wav")
var boom_sound = preload("res://Assets/boom.wav")
var hurt_sound = preload("res://Assets/hurt.wav")
var asteroid_scene = preload("res://Scenes/asteriod.tscn")
var money = 0
var offline_message = ""
var fire_rate_cost = 60
var health = 5
var game_over = false
var spawn_timer
var wave = 0
var to_spawn = 0
var wave_active = false
var multishot_cost = 150
var repair_cost = 40
var max_health = 5
var boss_spawned = false
var damage_cost = 100
var best_wave = 0
var max_health_cost = 120
const save_path = "user://save.json"
var upgrades_bought = 0
var payout_scale = 0.5
var crit_chance_cost = 200
var menu_open = false
var prestige_level = 0
var selected_ship = "ship0"
var hitstop_active = false
var bomb_cd_cost = 300
var bomb_dmg_cost = 250
var bomb_twice_cost = 1500
var base_max_health = 5
var offline_level = 0
var offline_cost = 1000
var last_played_time = 0
var total_money_earned = 0
@onready var death_menu = $DeathMenu
@onready var stats_label = $DeathMenu/ColorRect/VBoxContainer/StatsLabel

func start_next_wave():
	boss_spawned = false
	wave += 1
	if wave %5 == 0:
		to_spawn = 1
	else:
		to_spawn = 4 + wave * 2
	wave_active = true
	spawn_timer.wait_time = max(0.3, 1.0 - wave * 0.05)
	spawn_timer.start()
	update_ui()

func play_ui_sound():
	ui_sound.play()

func play_upgrade_sound():
	upgrade_sound.play()

func _ready():
	for button in find_children("*", "Button"):
		if upgrade_panel.is_ancestor_of(button) and button.name != "Closeshop":
			button.pressed.connect(play_upgrade_sound)
		else:
			button.pressed.connect(play_ui_sound)
	prestige.pressed.connect(do_prestige)
	money_label.position = Vector2(20, 20)
	money_label.add_theme_font_size_override("font_size", 28)
	spawn_timer = Timer.new()
	spawn_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	spawn_timer.timeout.connect(spawn_asteroid)
	add_child(spawn_timer)
	
	death_menu.visible = false
	$DeathMenu/ColorRect/VBoxContainer/Restart.pressed.connect(restart_game)
	
	combo_timer = Timer.new()
	combo_timer.one_shot = true
	combo_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	combo_timer.wait_time = 2.0
	combo_timer.timeout.connect(reset_combo)
	add_child(combo_timer)
	pause_menu.visible = false
	upgrade_panel.visible = false
	upgrade_prompt.visible = true
	$CanvasLayer/Pausemenu/VBoxContainer/Close.pressed.connect(toggle_pause)
	$CanvasLayer/Pausemenu/VBoxContainer/Resume.pressed.connect(toggle_pause)
	$CanvasLayer/Pausemenu/VBoxContainer/Restart.pressed.connect(func():get_tree().paused = false; get_tree().reload_current_scene())
	$CanvasLayer/Pausemenu/VBoxContainer/Quit.pressed.connect(func(): get_tree().quit())
	$CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Closeshop.pressed.connect(toggle_upgrade_menu)
	firerate.pressed.connect(buy_fire_rate)
	multishot.pressed.connect(buy_multishot)
	repair.pressed.connect(buy_repair)
	damage.pressed.connect(buy_damage)
	maxhealth.pressed.connect(buy_max_health)
	crit.pressed.connect(buy_crit_chance)
	bomb_cooldown.pressed.connect(buy_bomb_cooldown)
	bomb_damage.pressed.connect(buy_bomb_damage)
	bomb_double.pressed.connect(buy_bomb_double)
	offline_btn.pressed.connect(buy_offline_upgrade)
	load_game()
	player.apply_ship_color(Ships.DATA[selected_ship]["color"])
	recalculate_max_health()
	if health <= 0:
		health = max_health
	start_next_wave()

func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()

func toggle_pause():
	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused
	if get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		upgrade_prompt.visible = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		upgrade_prompt.visible = true

func shake(intensity = 10.0, duration = 0.2):
	if not camera:
		return
	var tween = create_tween()
	var steps = 10
	for i in steps:
		var rand_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", rand_offset, duration /steps)
	tween.tween_property(camera, "offset", Vector2.ZERO, duration / steps)

func update_boss_health(new_health):
	boss_health_bar.value = new_health
	if new_health <= 0:
		boss_health_bar.visible = false

func spawn_boss():
	var boss = asteroid_scene.instantiate()
	boss.is_boss = true
	boss.tint = Color(0.658, 0.144, 0.704, 1.0)
	boss.size = 5.0
	boss.health = int(150 + get_level() * 7)
	boss.damage = 10
	boss.speed = 50
	boss.value = 100 + wave * 20
	add_child(boss)
	boss.position = Vector2(get_viewport_rect().size.x/ 2, -150)
	boss_health_bar.visible = true
	boss_health_bar.max_value = boss.health
	boss_health_bar.value = boss.health
	update_ui()

func spawn_asteroid():
	if game_over:
		return
	if wave % 5 == 0:
		if not boss_spawned:
			boss_spawned = true
			spawn_boss()
		to_spawn = 0
		spawn_timer.stop()
		return
	var asteroid = asteroid_scene.instantiate()
	var screen = get_viewport_rect().size
	var roll = randf()
	var level = get_level()
	var big_chance = min(0.3, wave * 0.04)
	var medium_chance = min(0.4, wave * 0.1)
	var base_value = 2
	if roll < big_chance:
		asteroid.tint = Color(0.6, 0.0, 0.13, 1.0)
		asteroid.size = 4.0
		asteroid.health = 5 + level * 0.7
		asteroid.damage = 3 + floori(wave / 5.0)
		asteroid.splits_left = 1
		asteroid.speed = 90 + level * 11
		base_value = 10
	elif roll < big_chance + medium_chance:
		asteroid.tint = Color(0.7, 0.5, 0.0, 1.0)
		asteroid.size = 3.4
		asteroid.health = 5 + level * 0.6
		asteroid.damage = 3 + floori(wave / 5.0)
		asteroid.speed = 175 + level * 12
		base_value = 5
	else:
		asteroid.tint = Color(0.773, 0.763, 0.003, 1.0) 
		asteroid.size = 2.5
		asteroid.health = 3 + level * 0.5
		asteroid.damage = 1 + floori(wave / 5.0)
		asteroid.speed = 300 + level * 22
		base_value = 2
	asteroid.value = int(base_value * (1 + wave * 0.15))
	add_child(asteroid)
	asteroid.position = Vector2(randf_range(60, screen.x - 60), -60)
	to_spawn -= 1
	if to_spawn <= 0:
		spawn_timer.stop()

func boss_reward():
	health = min(max_health, health + 3)
	save_game()
	update_ui()

func _process(_delta):
	if game_over or not wave_active:
		return
	if to_spawn <= 0 and get_tree().get_nodes_in_group("asteroids").size() == 0:
		wave_active = false
		best_wave = max(best_wave, wave)
		save_game()
		update_ui()
		start_next_wave()

func add_money(amount, from_kill = false):
	var combo_mult = 1.0
	if from_kill:
		combo_mult = 1.0 + ((combo - 1) * 0.2)
	var prestige_mult = 1.0 + (prestige_level * 0.1)
	var ship_money_mult = Ships.DATA[selected_ship]["shipperk"].get("money", 1.0)
	var final_money = int(ceil(amount * payout_scale * prestige_mult * ship_money_mult * combo_mult))
	money += final_money
	total_money_earned += final_money
	update_ui()

func combo_kill():
	if combo < 10:
		combo = combo + 1
	combo_timer.start(2.0)
	update_ui()

func reset_combo():
	combo = 1
	update_ui()

func recalculate_max_health():
	var ship_hp_mult = Ships.DATA[selected_ship]["shipperk"].get("max_health", 1.0)
	max_health = int(base_max_health * ship_hp_mult)
	if health > max_health:
		health = max_health

func take_damage(amount):
	if game_over:
		return
	health -= amount
	play_sound(hurt_sound)
	shake(15.0, 0.3)
	if health <= 0:
		health = 0
		game_over = true
		spawn_timer.stop()
		best_wave = max(best_wave, wave)
		save_game()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		death_menu.visible = true
		stats_label.text = "Total Money Earned: $" + str(total_money_earned) + "\n\nWaves Survived: " + str(wave)
	update_ui()

func update_ui():
	if game_over:
		return
	var status = "Wave " + str(wave)
	if wave % 5 == 0:
		status += " BOSS IS COMING"
	
	if combo > 1: status = status + "\ncombo x" + str(combo) + "!"
		
	if player.bomb_ready:
		status += "\nBOMB IS PREPPED (PRESS RIGHT CLICK)"
	else:
		status += "\n Bomb is Recharging"
	
	var final_text = ""
	if offline_message != "":
		final_text = offline_message + "\n\n"

	money_label.text = final_text + status + "\nHealth " + str(health) + "/" + str(max_health) + "\nMoney: " + str(money)
		
	firerate.text = "Faster Fire\n$" + str(fire_rate_cost)
	firerate.disabled = money < fire_rate_cost
		
	if player.bullet_count < 5:
		multishot.text = "Multishot\n$" + str(multishot_cost)
		multishot.disabled = money < multishot_cost
	else: 
		multishot.text = "Multishot Is MAX"
		multishot.disabled = true
		
	if health < max_health and not game_over:
		repair.text = "Repair +1\n$" + str(repair_cost)
		repair.disabled = money < repair_cost
	else:
		repair.text = "Health Full"
		repair.disabled = true

	damage.text = "Damage +1\n$" + str(damage_cost)
	damage.disabled = money < damage_cost

	if base_max_health < 15:
		maxhealth.text = "Max Health +1\n$" + str(max_health_cost)
		maxhealth.disabled = money < max_health_cost
	else:
		maxhealth.text = "Max Health is MAX"
		maxhealth.disabled = true

	if player.bomb_cooldown > 2.0:
		bomb_cooldown.text = "Bomb Cooldown -1s\n$" + str(bomb_cd_cost)
		bomb_cooldown.disabled = money < bomb_cd_cost
	else:
		bomb_cooldown.text = "NO MORE UPGRADES BUD"
		bomb_cooldown.disabled = true
	bomb_damage.text = "Bomb Damage +3\n$" + str(bomb_dmg_cost)
	bomb_damage.disabled = money < bomb_dmg_cost

	if not player.bomb_twice:
		bomb_double.text = "Double Bomb\n$" + str(bomb_twice_cost)
		bomb_double.disabled = money < bomb_twice_cost
	else:
		bomb_double.text = "Double Bomb Max"
		bomb_double.disabled = true
	if offline_level == 0:
		offline_btn.text = "Unlock Offline Money\n$" + str(offline_cost)
	else:
		offline_btn.text = "Offline Money" + str(offline_level) + "/sec\n$" + str(offline_cost)
	offline_btn.disabled = money < offline_cost
	if player.base_crit_chance < 0.5:
		crit.text = "Crit Chance % +5\n$" + str(crit_chance_cost)
		crit.disabled = money < crit_chance_cost
	else:
		crit.text = "Crit Chance Max"
		crit.disabled = true
	if wave >= 20:
		prestige.text = "PRESTIGE (10% Money)\nLevel: " + str(prestige_level)
		prestige.disabled = false
	else:
		prestige.text = "LOCKED (Wave 20)\nLevel: " + str(prestige_level)
		prestige.disabled = true


func toggle_upgrade_menu():
	menu_open = not menu_open
	upgrade_panel.visible = menu_open
	upgrade_prompt.visible = not menu_open
	get_tree().paused = menu_open
	if menu_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode ==  KEY_ESCAPE:
			if menu_open:
				toggle_upgrade_menu()
			else:
				toggle_pause()
			return
		if event.keycode == KEY_M:
			if not get_tree().paused or menu_open:
				toggle_upgrade_menu()
			return
		if event.keycode == KEY_R and game_over:
			get_tree().paused = false
			get_tree().reload_current_scene()
			return

func buy_damage():
	if money >= damage_cost:
		money -= damage_cost
		upgrades_bought += 1
		player.base_bullet_damage += 1
		damage_cost = int(damage_cost * 1.8)
		player.recalculate()
		update_ui()
		save_game()

func buy_max_health():
	if base_max_health >= 15:
		return
	if money >= max_health_cost:
		money -= max_health_cost
		upgrades_bought += 1
		base_max_health += 1
		max_health_cost = int(max_health_cost * 1.6)
		recalculate_max_health()
		if not game_over:
			health += 1
		update_ui()
		save_game()

func buy_crit_chance():
	if player.crit_chance >= 0.5:
		return
	if money >= crit_chance_cost:
		money -= crit_chance_cost
		upgrades_bought += 1
		player.base_crit_chance += 0.05
		crit_chance_cost = int(crit_chance_cost * 2.0)
		player.recalculate()
		update_ui()
		save_game()

func buy_multishot():
	if player.bullet_count >= 5:
		return
	if money >= multishot_cost:
		money -= multishot_cost
		upgrades_bought += 1
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
		upgrades_bought += 1
		player.base_fire_delay = max(0.1, player.base_fire_delay * 0.85)
		fire_rate_cost = int(fire_rate_cost * 2)
		player.recalculate()
		update_ui()
		save_game()

func buy_bomb_cooldown():
	if money >= bomb_cd_cost:
		money -= bomb_cd_cost
		player.bomb_cooldown = max(2.0, player.bomb_cooldown - 1.0)
		bomb_cd_cost = int(bomb_cd_cost * 1.5)
		update_ui()
		save_game()

func buy_bomb_damage():
	if money >= bomb_dmg_cost:
		money -= bomb_dmg_cost
		player.bomb_damage += 3
		bomb_dmg_cost = int(bomb_dmg_cost * 1.5)
		update_ui()
		save_game()

func buy_bomb_double():
	if money >= bomb_twice_cost and not player.bomb_twice:
		money -= bomb_twice_cost
		player.bomb_twice = true
		update_ui()
		save_game()

func buy_offline_upgrade():
	if money >= offline_cost:
		money -= offline_cost
		offline_level += 1
		offline_cost = int(offline_cost * 2.0)
		update_ui()
		save_game()

func play_sound(stream):
	var p = AudioStreamPlayer.new()
	p.volume_db = -8
	p.stream = stream
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func get_level():
	return wave + upgrades_bought * 0.5

func do_prestige():
	if wave < 20:
		return
	prestige_level += 1
	money = 0
	health = 5
	max_health = 5
	upgrades_bought = 0
	wave = 0
	offline_level = 0
	offline_cost = 1000
	player.base_fire_delay = 0.4
	player.bullet_count = 1
	player.base_bullet_damage = 2
	player.base_crit_chance = 0.1
	fire_rate_cost = 60
	multishot_cost = 150
	repair_cost = 40
	damage_cost = 100
	max_health_cost = 120
	crit_chance_cost = 200
	player.bomb_cooldown = 12.0
	player.bomb_damage = 6
	player.bomb_twice = false
	bomb_cd_cost = 300
	bomb_dmg_cost = 250
	base_max_health = 5
	recalculate_max_health()
	health = max_health
	toggle_upgrade_menu()
	player.recalculate()
	save_game()
	start_next_wave()


# not sure if mentioned, but ai was used in the assitance of creating the below function
func save_game():
	var data = {
		"money": money,
		"best_wave": best_wave,
		"fire_delay": player.base_fire_delay,
		"fire_rate_cost": fire_rate_cost,
		"bullet_count": player.bullet_count,
		"multishot_cost": multishot_cost,
		"bullet_damage": player.base_bullet_damage,
		"damage_cost": damage_cost,
		"repair_cost": repair_cost,
		"max_health": max_health,
		"max_health_cost": max_health_cost,
		"upgrades_bought": upgrades_bought,
		"health": health,
		"crit_chance": player.base_crit_chance,
		"crit_chance_cost": crit_chance_cost,
		"prestige_level": prestige_level,
		"selected_ship": selected_ship,
		"bomb_cooldown": player.bomb_cooldown,
		"bomb_damage": player.bomb_damage,
		"bomb_twice": player.bomb_twice,
		"bomb_cd_cost": bomb_cd_cost,
		"bomb_dmg_cost": bomb_dmg_cost,
		"base_max_health": base_max_health,
		"offline_level": offline_level,
		"offline_cost": offline_cost,
		"total_money_earned": total_money_earned,
		"last_played": Time.get_unix_time_from_system()
	}

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
# not sure if mentioned, but ai was used in the assitance of creating the below function
func load_game():
	if not FileAccess.file_exists(save_path):
		return
	var file = FileAccess.open(save_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		return
	health = int(data.get("health", max_health))
	money = int(data.get("money", 0))
	best_wave = int(data.get("best_wave", 0))
	player.base_fire_delay = float(data.get("fire_delay", 0.4))
	fire_rate_cost = int(data.get("fire_rate_cost", 10))
	player.bullet_count= int(data.get("bullet_count", 1))
	multishot_cost = int(data.get("multishot_cost", 25))
	player.base_bullet_damage = int(data.get("bullet_damage", 1))
	damage_cost = int(data.get("damage_cost", 40))
	repair_cost = int(data.get("repair_cost", 15))
	max_health = int(data.get("max_health", 5))
	max_health_cost = int(data.get("max_health_cost", 30))
	upgrades_bought = int(data.get("upgrades_bought", 0 ))
	player.base_crit_chance = float(data.get("crit_chance", 0.1))
	crit_chance_cost = int(data.get("crit_chance_cost", 200))
	prestige_level = int(data.get("prestige_level", 0))
	selected_ship = str(data.get("selected_ship", "ship0"))
	player.bomb_cooldown = float(data.get("bomb_cooldown", 12.0))
	player.bomb_damage = int(data.get("bomb_damage", 6))
	player.bomb_twice = bool(data.get("bomb_twice", false))
	bomb_cd_cost = int(data.get("bomb_cd_cost", 300))
	bomb_dmg_cost = int(data.get("bomb_dmg_cost", 250))
	base_max_health = int(data.get("base_max_health", 5))
	recalculate_max_health()
	offline_level = int(data.get("offline_level", 0))
	offline_cost = int(data.get("offline_cost", 1000))
	last_played_time = float(data.get("last_played", 0))
	total_money_earned = int(data.get("total_money_earned", 0))
	if last_played_time > 0 and offline_level > 0:
		var current_time = Time.get_unix_time_from_system()
		var seconds_away = int(current_time - last_played_time)
		if seconds_away > 5:
			var earned = seconds_away * offline_level
			money += earned
			offline_message = "YOU'RE BACK! You earned $" + str(earned) + " While Away!"
	player.recalculate()
