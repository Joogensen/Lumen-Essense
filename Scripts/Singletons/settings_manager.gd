extends Node

# Default settings
var settings = {
	"master_volume": 0.4,
	"music_volume": 0.4,
	"sfx_volume": 0.4,
	"fullscreen": false
}

func _ready():
	load_settings()

func save_settings():
	var file = FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	if file:
		file.store_var(settings)

func load_settings():
	if FileAccess.file_exists("user://settings.cfg"):
		var file = FileAccess.open("user://settings.cfg", FileAccess.READ)
		if file:
			var loaded = file.get_var()
			if loaded is Dictionary:
				# Safely merge loaded settings with defaults
				for key in settings:
					if loaded.has(key):
						settings[key] = loaded[key]
	apply_settings()

func apply_settings():
	# Ensure volume values are within a reasonable range (0.0 to 1.0)
	var master_vol = clamp(settings.get("master_volume", 0.4), 0.0, 1.0)
	var music_vol = clamp(settings.get("music_volume", 0.4), 0.0, 1.0)
	
	# Scale the SFX volume so it never exceeds a max value
	# Limiting SFX volume to a much quieter level
	var sfx_vol = clamp(settings.get("sfx_volume", 0.4), 0.0, 1.0) * 0.1  # Now capping at max 0.1

	# Audio settings (without using linear_to_db)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"), 
		master_vol  # Adjusting the volume level directly to match your desired range
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), 
		music_vol  # Similarly adjusting music volume
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"), 
		sfx_vol  # Adjusting SFX volume (scaled to quieter levels)
	)
	
	# Fullscreen setting (use window_set_mode)
	var fullscreen = settings.get("fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
