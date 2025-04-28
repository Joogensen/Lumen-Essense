extends Node

var music_player : AudioStreamPlayer
var background_music : AudioStream

func _ready():
	# Create an AudioStreamPlayer for background music if it doesn't exist.
	if not music_player:
		music_player = AudioStreamPlayer.new()
		add_child(music_player)

		# Preload the background music and assign it to the stream.
		background_music = preload("res://Audio/eerie-ambient-10-205803.mp3")  # Replace with the correct path
		music_player.stream = background_music

		# Set the music player's bus to the "Music" bus by name.
		music_player.bus = "Music"  # Set the bus by name ("Music")

		# Start playing the music
		
		music_player.play()

# Restart the music if needed (for example, after a death or level restart)
func restart_music():
	music_player.stop()  # Stop the music to restart it from the beginning
	music_player.play()  # Start playing again
