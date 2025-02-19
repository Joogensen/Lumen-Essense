extends StaticBody2D

@onready var color_rect = $ColorRect  
@onready var collision_shape = $CollisionShape2D  

func _ready():
	var uv = get_tree().root.get_node("Main/Player/PointLight2D")  # Adjust the path to your scene structure

	# Ensure the UV node exists and has the signal before connecting
	if uv and uv.has_signal("uv_active"):
		uv.uv_active.connect(_on_uv_activated)  # Connect the signal

	# Start invisible and disabled
	color_rect.visible = false
	collision_shape.set_deferred("disabled", true)

func _on_uv_activated(is_active):
	print("uv is active")
	color_rect.visible = is_active  # Toggle visibility
	collision_shape.set_deferred("disabled", !is_active)  # Enable/disable collision
