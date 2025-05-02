extends Control

@export var settings_scene: PackedScene
var current_settings_instance = null

func _ready():
	if settings_scene == null:
		settings_scene = preload("res://Scenes/SettingsLayer.tscn")
	
	# Apply saved audio settings when starting (moved from Main.gd)
	if SettingsManager.settings != null:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(max(SettingsManager.settings.master_volume, 0.001)))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(max(SettingsManager.settings.music_volume, 0.001)))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(max(SettingsManager.settings.sfx_volume, 0.001)))

func _on_start_pressed():
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
