extends Node2D

@onready var sprite2D = $Sprite2D2

var tries_left = 30 # Try connecting 30 times

func _ready():
	sprite2D.visible = false # <<< HIDE IT IMMEDIATELY
	call_deferred("_connect_to_uv")

func _connect_to_uv():
	if tries_left <= 0:
		print("❌ UV Message could not find UV light after multiple tries.")
		return
	
	var uv = get_tree().root.get_node_or_null("Main/Player/PointLight2D")
	if uv and uv.has_signal("uv_active"):
		uv.uv_active.connect(_on_uv_activated)
		print("✅ UV Message connected to UV light!")
	else:
		tries_left -= 1
		call_deferred("_connect_to_uv") # Try again next frame

func _on_uv_activated(is_active):
	sprite2D.visible = is_active # <<< only visible if UV is on
