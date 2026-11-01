extends Area2D
var damage = 1
var speed = 1200
var pierce = 0
var is_player_bullet = false
var is_explosive = false

func _ready():
	add_to_group("bullets")
	area_entered.connect(_on_area_entered)

func _process(delta):
	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	var screen = get_viewport_rect().size
	if position.x < -50 or position.x > screen.x + 50 or position.y < -50 or position.y > screen.y + 50:
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("player") and not is_player_bullet:
		area.get_parent().take_damage(damage)
		queue_free()
	elif area.is_in_group("asteroids") and is_player_bullet and is_explosive:
		var main = get_parent()
		for a in get_tree().get_nodes_in_group("asteroids"):
			if not a.is_queued_for_deletion() and a != area:
				if a.global_position.distance_to(global_position) < 100:
					a.take_hit(int(damage * 0.5))
		queue_free()
