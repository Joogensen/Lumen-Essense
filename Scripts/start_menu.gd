extends Control

@export var settings_scene: PackedScene
var current_settings_instance = null  # Track the active settings instance

func _ready() -> void:
	if settings_scene == null:
		settings_scene = preload("res://Scenes/SettingsLayer.tscn")

	# Immediately apply saved audio settings when starting
	if Main.has_method("apply_saved_audio_settings"):
		Main.apply_saved_audio_settings()

func _on_start_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_settings_pressed() -> void:
	if current_settings_instance:
		current_settings_instance.queue_free()

	current_settings_instance = settings_scene.instantiate()
	add_child(current_settings_instance)
	current_settings_instance.open(false, true)

	current_settings_instance.return_to_main_menu.connect(_on_settings_closed)
	current_settings_instance.settings_closed.connect(_on_settings_closed)

func _on_settings_closed():
	if current_settings_instance:
		current_settings_instance.queue_free()
		current_settings_instance = null

func _on_exit_pressed() -> void:
	get_tree().quit()
