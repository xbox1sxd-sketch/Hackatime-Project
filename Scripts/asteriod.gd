extends Area2D

var size = 1.0
var health = 1
var damage = 1
var value = 5
var speed = 150

func _ready():
	add_to_group("asteroids")
	scale = Vector2.ONE * size
	area_entered.connect(_on_area_entered)
	
func _process(delta):
	position.y += speed * delta
	if position.y > 700:
		get_parent().take_damage(1)
		queue_free()
		
func _on_area_entered(area):
	if is_queued_for_deletion():
		return
	if area.is_in_group("bullets"):
		health -= area.damage
		area.queue_free()
		if health <= 0:
			get_parent().add_money(value)
			queue_free()
	elif area.is_in_group("player"):
		get_parent().take_damage(damage)
		queue_free()
