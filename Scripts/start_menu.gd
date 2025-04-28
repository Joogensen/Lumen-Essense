extends Control

@export var settings_scene: PackedScene
var current_settings_instance = null  # Track the active settings instance

func _ready() -> void:
	if settings_scene == null:
		settings_scene = preload("res://Scenes/SettingsLayer.tscn")

func _on_start_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_settings_pressed() -> void:
	# Remove any existing settings instance first
	if current_settings_instance:
		current_settings_instance.queue_free()
	
	# Create and show new settings
	current_settings_instance = settings_scene.instantiate()
	add_child(current_settings_instance)
	current_settings_instance.open(false, true)  # Not from pause, from main
	
	# Connect signals with proper references
	current_settings_instance.return_to_main_menu.connect(_on_settings_closed)
	current_settings_instance.settings_closed.connect(_on_settings_closed)

func _on_settings_closed():
	if current_settings_instance:
		current_settings_instance.queue_free()
		current_settings_instance = null

func _on_exit_pressed() -> void:
	get_tree().quit()
