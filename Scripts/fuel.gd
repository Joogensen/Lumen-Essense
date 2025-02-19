extends Area2D

signal collected  # Define the signal

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":  
		collected.emit()  # Emit the signal when the battery is collected
		queue_free()  # Remove the battery
