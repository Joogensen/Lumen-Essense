extends Area2D

func _ready():
	connect("body_entered", _on_body_entered)  # Connect signal

func _on_body_entered(body):
	if body.name == "Player":  # Check if the player touches the boundary
		body.die()  # Call the player's death function
