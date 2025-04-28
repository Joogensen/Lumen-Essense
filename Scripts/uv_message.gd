extends Node2D  # No collision needed, so Node2D is enough

@onready var sprite2D = $Sprite2D2

func _ready():
	var uv = get_tree().root.get_node("Main/Player/PointLight2D")

	# Ensure the UV node exists and has the signal before connecting
	if uv and uv.has_signal("uv_active"):
		uv.uv_active.connect(_on_uv_activated)
		
		sprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full white (or whatever you want)

	# Start invisible
	sprite2D.visible = false

func _on_uv_activated(is_active):
	print("UV mode toggled:", is_active)
	sprite2D.visible = is_active  # Only control visibility
