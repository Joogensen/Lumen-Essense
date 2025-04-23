extends Area2D

var has_triggered = false

func _on_body_entered(body):
	if has_triggered or body.name != "Player":
		return

	has_triggered = true

	DialogManager.start_dialog(body.global_position, [
		{"speaker": "Lantern", "text": "Go slow. Something’s off here..."},
		{"speaker": "Player", "text": "You're... talking?"}
	])
