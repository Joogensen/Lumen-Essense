extends Node

const SAVEFILE = "user://SAVEFILE.save"

var game_data = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_data()


func load_data():
	var file = File.new()
	if not file.file_exists(SAVEFILE):
		game_data = {
			"music_vol": 100,
			"sfx_vol": 100,
			"Super Secret Settings": false
		}
		save_data()
	file.open(SAVEFILE, File.READ)
	game_data = file.get_var()
	file.close()
	
func save_data():
	var file = File.new()
	file.open(SAVEFILE, file.WRITE)
	file.store_var(game_data)
	file.close()
