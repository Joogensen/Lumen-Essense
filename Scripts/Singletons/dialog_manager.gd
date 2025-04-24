extends Node

@onready var text_box_scene = preload("res://Scenes/TextBox.tscn")

var dialog_lines: Array = []
var current_line_index = 0

var text_box
var text_box_position: Vector2

var is_dialog_active = false
var can_advance_line = false

var original_camera_zoom = Vector2.ONE

func start_dialog(position: Vector2, lines: Array):
	if is_dialog_active:
		return

	# Validate input format
	for line in lines:
		if typeof(line) != TYPE_DICTIONARY or not line.has("text"):
			push_error("DialogManager: Invalid dialog line format.")
			return

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_error("No player found in 'player' group")
		return

	var player = players.front()
	player.set_dialog_mode(true)
	GameState.is_in_dialog = true

	original_camera_zoom = player.get_node("Camera2D").zoom
	var camera = player.get_node("Camera2D")
	var tween = create_tween()
	tween.tween_property(camera, "zoom", camera.zoom * 1.2, 0.4).set_trans(Tween.TRANS_SINE)

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

	player.get_node("PlayerTextBoxWrapper/PlayerTextBox").hide()
	player.get_node("LanternTextBoxWrapper/LanternTextBox").hide()

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

	# Auto-advance after delay
	var delay = max(2.0, text.length() * 0.08)
	await get_tree().create_timer(delay).timeout
	if is_dialog_active and can_advance_line:
		advance_dialog()

func _on_text_box_finished_displaying():
	can_advance_line = true

func _unhandled_input(event):
	if event.is_action_pressed("advance_dialog") and is_dialog_active:
		if not can_advance_line:
			# Fast-forward typewriter effect
			text_box.skip_to_end()
		else:
			advance_dialog()

func advance_dialog():
	text_box.hide()
	current_line_index += 1

	if current_line_index >= dialog_lines.size():
		end_dialog()
	else:
		_show_text_box()

func end_dialog():
	is_dialog_active = false
	current_line_index = 0

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_error("No player found in 'player' group")
		return

	var player = players.front()
	player.set_dialog_mode(false)
	GameState.is_in_dialog = false

	var camera = player.get_node_or_null("Camera2D")
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "zoom", original_camera_zoom, 0.4).set_trans(Tween.TRANS_SINE)
