extends Control

@export var settings_scene: PackedScene
var accepting_input = true

func _ready() -> void:
	if settings_scene == null:
		settings_scene = preload("res://Scenes/SettingsLayer.tscn")
	hide()

func _process(_delta: float) -> void:
	if accepting_input:
		# Use the action mapping for ESC key
		if Input.is_action_just_pressed("ui_cancel"):
			if get_tree().paused:
				resume()
			else:
				pause()

func resume():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false

func pause():
	GameState.map_open = false
	await get_tree().process_frame
	get_tree().paused = true
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_resume_pressed() -> void:
	resume()

func _on_settings_pressed() -> void:
	var settings = settings_scene.instantiate()
	add_child(settings)
	settings.open(true, false)  # From pause, not from main
	settings.settings_closed.connect(_on_settings_closed)
	hide()

func _on_settings_closed():
	show()

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	resume()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
