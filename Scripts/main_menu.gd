extends Control

@onready var reset: Button = $VBoxContainer/Reset
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$VBoxContainer/Play.pressed.connect(start_game)
	$VBoxContainer/Quit.pressed.connect(quit_game)
	reset.pressed.connect(show_reset_warning)
	confirmation_dialog.confirmed.connect(delete_save_data)


func start_game():
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func quit_game():
	get_tree().quit()

func show_reset_warning():
	confirmation_dialog.popup_centered()

func delete_save_data():
	var save_path = "user://save.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)

	reset.text = "DATA RESET"
	reset.disabled = true
