extends CanvasLayer

signal settings_closed
signal return_to_main_menu

@onready var master_slider = $PanelContainer/MarginContainer/VBoxContainer/MasterSlider
@onready var music_slider = $PanelContainer/MarginContainer/VBoxContainer/MusicSlider
@onready var sfx_slider = $PanelContainer/MarginContainer/VBoxContainer/SFXSlider

var opened_from_pause := false
var opened_from_main := false

func _ready():
	hide()
	# Initialize slider values
	master_slider.value = SettingsManager.settings.master_volume
	music_slider.value = SettingsManager.settings.music_volume
	sfx_slider.value = SettingsManager.settings.sfx_volume
	# Connect slider signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

func _on_master_volume_changed(value: float):
	SettingsManager.settings.master_volume = value
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(value)
	)

func _on_music_volume_changed(value: float):
	SettingsManager.settings.music_volume = value
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), 
		linear_to_db(value)
	)

func _on_sfx_volume_changed(value: float):
	SettingsManager.settings.sfx_volume = value
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value)
	)

func open(from_pause_menu := false, from_main_menu := false):
	show()
	opened_from_pause = from_pause_menu
	opened_from_main = from_main_menu
	if from_pause_menu:
		get_tree().paused = true


func _on_apply_pressed():
	# Save settings
	SettingsManager.settings.master_volume = $PanelContainer/MarginContainer/VBoxContainer/MasterSlider.value
	SettingsManager.settings.music_volume = $PanelContainer/MarginContainer/VBoxContainer/MusicSlider.value
	SettingsManager.settings.sfx_volume = $PanelContainer/MarginContainer/VBoxContainer/SFXSlider.value
	SettingsManager.settings.fullscreen = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/FullscreenCheckbox.button_pressed
	SettingsManager.save_settings()
	
	if opened_from_main:
		emit_signal("return_to_main_menu")
		queue_free()
	else:
		emit_signal("settings_closed")
	hide()


func _on_back_pressed() -> void:
	hide()
	if opened_from_pause:
		get_tree().paused = false
		emit_signal("settings_closed")
	elif opened_from_main:
		emit_signal("return_to_main_menu")
		queue_free()
	else:
		emit_signal("settings_closed")
