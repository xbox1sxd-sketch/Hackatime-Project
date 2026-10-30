extends TextureRect

@export var speed = 50.0
@export var is_second = false

func _ready():
	stretch_mode = STRETCH_SCALE
	settexturerect()
	get_viewport().size_changed.connect(settexturerect)
	
func settexturerect():
	var screen = get_viewport_rect().size
	size = screen
	position.x = 0
	if is_second:
		position.y = -screen.y
	else:
		position.y = 0

func _process(delta):
	var screen_h = get_viewport_rect().size.y
	position.y = position.y + speed * delta
	if position.y >= screen_h:
		position.y = position.y - screen_h * 2
