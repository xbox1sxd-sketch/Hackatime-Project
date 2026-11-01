extends Area2D
var damage = 1
var speed = 1200
var pierce = 0

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
