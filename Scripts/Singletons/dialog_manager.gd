extends Node

@onready var text_box_scene = preload("res://Scenes/TextBox.tscn")

var dialog_lines: Array = []
var current_line_index = 0

var text_box
var text_box_position: Vector2

var is_dialog_active = false
var can_advance_line = false

func start_dialog(position: Vector2, lines: Array):
	if is_dialog_active:
		return

	# Validate input format
	for line in lines:
		if typeof(line) != TYPE_DICTIONARY or not line.has("text"):
			push_error("DialogManager: Invalid dialog line format.")
			return

	dialog_lines = lines
	text_box_position = position
	_show_text_box()
	is_dialog_active = true



func _show_text_box():
	var current_line = dialog_lines[current_line_index]
	var speaker = current_line.get("speaker", "???")
	var text = current_line.get("text", "")

	var players = get_tree().get_nodes_in_group("player")

	if players.is_empty():
		push_error("DialogManager: No node in group 'player' found!")
		return

	var player = players.front()

	# Hide both first
	player.get_node("PlayerTextBoxWrapper/PlayerTextBox").hide()
	player.get_node("LanternTextBoxWrapper/LanternTextBox").hide()

	# Choose which box to show
	match speaker:
		"Player":
			text_box = player.get_node("PlayerTextBoxWrapper/PlayerTextBox")
		"Lantern":
			text_box = player.get_node("LanternTextBoxWrapper/LanternTextBox")
		_:
			text_box = player.get_node("PlayerTextBoxWrapper/PlayerTextBox")  # fallback
	
	if not text_box.finished_displaying.is_connected(_on_text_box_finished_displaying):
		text_box.finished_displaying.connect(_on_text_box_finished_displaying)

	text_box.display_text(speaker, text)
	text_box.show()

	can_advance_line = false


	
func _on_text_box_finished_displaying():
	can_advance_line = true

func _unhandled_input(event):
	if(
		event.is_action_pressed("advance_dialog") &&
		is_dialog_active &&
		can_advance_line
	):
		text_box.queue_free()
		
		current_line_index += 1
		if current_line_index >= dialog_lines.size():
			is_dialog_active = false
			current_line_index = 0
			return
			
		_show_text_box()
