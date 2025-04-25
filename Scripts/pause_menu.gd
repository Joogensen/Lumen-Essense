extends Control

var accepting_input = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	testEsc()

# resume game, hide ui
func resume():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false

# pause game, show ui
func pause():
	GameState.map_open = false
	await get_tree().process_frame
	get_tree().paused = true
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# check if 'esc' key has been pressed
func testEsc():
	if accepting_input:
		if Input.is_action_just_pressed("ui_cancel") and !get_tree().paused:
			pause()
		elif Input.is_action_just_pressed("ui_cancel") and get_tree().paused:
			resume()
	else:
		pass


func _on_resume_pressed() -> void:
	resume()


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()


func _on_exit_pressed() -> void:
	resume()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
	#get_tree().quit()
