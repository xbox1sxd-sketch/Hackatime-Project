extends TextureRect

var speed = 50.0

func _process(delta):
	position.y += speed * delta
	var screen_height = get_viewport_rect().size.y

	if position.y >= screen_height:
		position.y -= screen_height * 2
