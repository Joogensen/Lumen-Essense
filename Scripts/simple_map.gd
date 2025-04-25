extends CanvasLayer

var world_size: Vector2
var map_size

@onready var player = $".."
@onready var icon = $SubViewportContainer/Sprite2D


func _ready() -> void:
	map_size = Vector2(935, 140)
	world_size = Vector2(6090, 1250)
	hide()


func _process(_delta: float) -> void:
	if player and icon:
		var player_world_position = player.position
		var scaled_position_x = player_world_position.x / world_size.x * map_size.x
		var scaled_position_y = player_world_position.y / world_size.y * map_size.y * 1.35
		icon.position.x = scaled_position_x + 30
		icon.position.y = scaled_position_y + 158
	
	if GameState.is_player_dead:
		GameState.map_open = false
	elif Input.is_action_just_pressed("ui_map"):
		GameState.map_open = !GameState.map_open
	
	if GameState.map_open:
		show()
	else:
		hide()
	
