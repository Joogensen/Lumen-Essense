extends StaticBody2D

@onready var sprite2D = $Sprite2D
@onready var collision_shape = $CollisionShape2D

var tries_left = 30

func _ready():
	sprite2D.visible = false # <<< HIDE IT IMMEDIATELY
	collision_shape.set_deferred("disabled", true)
	call_deferred("_connect_to_uv")

func _connect_to_uv():
	if tries_left <= 0:
		print("❌ UV Platform could not find UV light after multiple tries.")
		return

	var uv = get_tree().root.get_node_or_null("Main/Player/PointLight2D")
	if uv and uv.has_signal("uv_active"):
		uv.uv_active.connect(_on_uv_activated)
		print("✅ UV Platform connected to UV light!")
	else:
		tries_left -= 1
		call_deferred("_connect_to_uv")

func _on_uv_activated(is_active):
	sprite2D.visible = is_active
	collision_shape.set_deferred("disabled", !is_active)
	
	if is_active:
		sprite2D.modulate = Color(0.0, 0.7, 1.0, 1.0) # Blue-ish UV color
	else:
		sprite2D.modulate = Color(1.0, 1.0, 1.0, 0.0) # Fully transparent when UV off
