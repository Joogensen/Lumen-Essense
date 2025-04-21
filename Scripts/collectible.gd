extends Area2D

signal collected  

func _ready():
	$AnimatedSprite2D.play("default")
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":  
		collected.emit()
		$AudioStreamPlayer2D.play()
		await $AudioStreamPlayer2D.finished
		queue_free()
