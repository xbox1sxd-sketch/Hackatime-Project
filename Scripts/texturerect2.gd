extends TextureRect

var speed = 50.0

func _process(delta):
	position.y += speed * delta
	if position.y >= 648:
		position.y -= 648 *2
