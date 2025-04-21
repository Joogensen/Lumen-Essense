extends Area2D

signal collected  

func _ready():
	$AnimatedSprite2D.play("default")
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		collected.emit()
		$AudioStreamPlayer2D.play()
		visible = false
		call_deferred("disable_collision_and_cleanup")

func disable_collision_and_cleanup():
	monitoring = false
	$CollisionShape2D.disabled = true
	await get_tree().create_timer(2.0).timeout
	queue_free()
