extends Control

@onready var reset: Button = $VBoxContainer/Reset
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog
@onready var ui_sound = $UISound
@onready var ship_row = $VBoxContainer/ShipRow
@onready var ship_preview = $VBoxContainer/ShipPreview

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$VBoxContainer/Play.pressed.connect(start_game)
	$VBoxContainer/Quit.pressed.connect(quit_game)
	reset.pressed.connect(show_reset_warning)
	confirmation_dialog.confirmed.connect(delete_save_data)
	for button in find_children("*", "Button"):
		button.pressed.connect(play_ui_sound)
	_build_ship_buttons()

func _build_ship_buttons():
	if ship_row == null:
		return
	for c in ship_row.get_children():
		c.queue_free()
		
	var best_wave = 0
	var selected_ship = "ship0"
	if FileAccess.file_exists("user://save.json"):
		var file = FileAccess.open("user://save.json", FileAccess.READ)
		if file.get_length() > 0:
			var data = JSON.parse_string(file.get_as_text())
			if data != null:
				best_wave = int(data.get("best_wave", 0))
				selected_ship = str(data.get("selected_ship", "ship0"))
	if ship_preview != null:
		ship_preview.self_modulate = Ships.DATA[selected_ship]["color"]
	for id in Ships.DATA:
		var ship = Ships.DATA[id]
		var label = ship["name"]
		if (ship["unlock_wave"]) > best_wave:
			label += " (w" + str(ship["unlock_wave"]) +")"
		elif id == selected_ship:
			label = "✓" + label
		var btn = Button.new()
		btn.text = label
		btn.tooltip_text = ship["text"]
		if ship["unlock_wave"] > best_wave:
			btn.disabled = true
		btn.add_theme_color_override("font_color", ship["color"])
		btn.pressed.connect(_select_ship.bind(id))
		ship_row.add_child(btn)

func _select_ship(id):
	var data = null
	if FileAccess.file_exists("user://save.json"):
		var file = FileAccess.open("user://save.json", FileAccess.READ)
		if file.get_length() > 0:
			data = JSON.parse_string(file.get_as_text())
	if data == null:
		data = {}
	data["selected_ship"] = id
	var f = FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	if ship_preview != null:
		ship_preview.self_modulate = Ships.DATA[id]["color"]
	_build_ship_buttons()
	

func start_game():
	await get_tree().create_timer(0.1).timeout #ai was used for this line
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func quit_game():
	get_tree().quit()

func show_reset_warning():
	confirmation_dialog.popup_centered()

func play_ui_sound():
	ui_sound.play()

func delete_save_data():
	var save_path = "user://save.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	reset.text = "DATA RESET"
	reset.disabled = true
	_build_ship_buttons()
