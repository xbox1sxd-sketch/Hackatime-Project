extends Area2D

var health = 5
var speed = 100
var shoot_timer = 1.5
var value = 15

func _ready():
	add_to_group("asteroids")
	scale = Vector2(0.5, 0.5)
	modulate = Color.CYAN
	area_entered.connect(on_area_entered)
	
func _process(delta):
	if position.y < 200:
		position.y += speed * delta
	else:
		shoot_timer -= delta
		if shoot_timer <= 0:
			shoot_timer = 1.5
			shoot()
	
func shoot():
	var bullet = preload("res://Scenes/Bullet.tscn").instantiate()
	bullet.speed = 400
	bullet.damage = 1
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	var dir = (get_parent().player.global_position - global_position).normalized() # ai was used for this line and the line below
	bullet.global_rotation = dir.angle()

func take_hit(amount, hit_pos = null):
	health -= amount
	if health <= 0:
		die()

func die():
	var main = get_parent()
	main.add_money(value, true)
	main.combo_kill()
	main.play_sound(main.boom_sound)
	
	# Dont know what to do with my time, so i guess ill make it explode
	
	var boom = CPUParticles2D.new()
	boom.position = global_position
	boom.one_shot = true
	boom.explosiveness = 1.0
	boom.amount = 15
	boom.lifetime = 0.13
	boom.color = Color.CYAN
	boom.finished.connect(boom.queue_free)
	main.add_child(boom)
	queue_free()
	
func on_area_entered(area):
	if area.is_in_group("player"):
		area.get_parent().take_damage(2)
		queue_free()
	
