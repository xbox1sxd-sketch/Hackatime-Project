extends Area2D
var damage = 1
var speed = 1200
func _ready():
	add_to_group("bullets")
func _process(delta):
	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	if position.x < -50 or position.x > 1200 or position.y < -50 or position.y > 700:
		queue_free()
