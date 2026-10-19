extends Area2D


var speed = 150

func _ready():
	area_entered.connect(_on_area_entered)
	
func _process(delta):
	position.y += speed * delta
	if position.y > 700:
		queue_free()
		
func _on_area_entered(area):
	if area.is_in_group("bullets"):
		area.queue_free()
		queue_free()
		
