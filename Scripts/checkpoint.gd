extends Area2D

@export var checkpoint_id: String
var activated = false

func _on_body_entered(body):
	if body.name == "Player" and not activated:
		GameState.last_checkpoint_id = checkpoint_id
		GameState.last_checkpoint_position = global_position
		activated = true
		print("Checkpoint reached:", checkpoint_id)
