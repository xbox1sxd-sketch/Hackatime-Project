extends Area2D
var damage = 1
var speed = 1200
var pierce = 0

func _ready():
	add_to_group("bullets")


func _process(delta):
	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	var screen = get_viewport_rect().size
	if position.x < -50 or position.x > screen.x + 50 or position.y < -50 or position.y > screen.y + 50:
		queue_free()
