extends Node

func _ready():
	print("Main ready.")
	apply_saved_audio_settings()

func safe_linear_to_db(value: float) -> float:
	return linear_to_db(max(value, 0.001))

func apply_saved_audio_settings():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), safe_linear_to_db(SettingsManager.settings.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), safe_linear_to_db(SettingsManager.settings.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), safe_linear_to_db(SettingsManager.settings.sfx_volume))
