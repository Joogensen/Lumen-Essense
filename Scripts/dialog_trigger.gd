extends Area2D

@export var dialog_data: DialogData  # this should be set in the Inspector

var has_triggered = false

func _on_body_entered(body):
	if has_triggered or body.name != "Player":
		return

	if dialog_data == null:
		push_error("DialogTrigger: dialog_data not assigned!")
		return

	has_triggered = true
	var dialog_position = body.global_position + Vector2(0, -100)
	DialogManager.start_dialog(dialog_position, dialog_data.lines, dialog_data.dialog_id)
