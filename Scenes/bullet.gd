extends Node2D

var speed = 1200

func _process(delta):
	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	if position.x < -50 or position.x > 1200 or position.y < -50 or position.y > 700:
		queue_free()
