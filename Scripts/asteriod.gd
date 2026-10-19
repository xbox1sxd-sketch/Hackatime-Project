extends Area2D


var speed = 150

func _ready():
	area_entered.connect(_on_area_entered)
	
func _process(delta):
	position.y += speed * delta
	if position.y > 700:
		get_parent().take_damage(1)
		queue_free()
		
func _on_area_entered(area):
	if area.is_in_group("bullets"):
		get_parent().add_money(5)
		area.queue_free()
		queue_free()
		
