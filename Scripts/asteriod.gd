extends Area2D

var size = 1.0
var health = 1
var damage = 1
var value = 5
var speed = 150
var tint = Color.WHITE
func _ready():
	add_to_group("asteroids")
	scale = Vector2.ONE * size
	modulate = tint
	area_entered.connect(_on_area_entered)
	
func _process(delta):
	position.y += speed * delta
	if position.y > 700:
		get_parent().take_damage(damage)
		queue_free()
		
func _on_area_entered(area):
	if is_queued_for_deletion():
		return
	if area.is_in_group("bullets"):
		area.queue_free()
		take_hit(area.damage)
	elif area.is_in_group("player"):
		get_parent().take_damage(damage)
		die(false)

func take_hit(amount):
	health -= amount
	if health <= 0:
		die(true)
	else:
		on_hit()

func on_hit():
	modulate = Color(2, 2, 2)
	create_tween().tween_property(self, "modulate", tint, 0.1)

func die(killed_by_player):
	if killed_by_player:
		get_parent().add_money(value)
		get_parent().play_sound(get_parent().boom_sound)
	queue_free()
