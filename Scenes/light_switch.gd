extends Area2D

@export var canvas_modulate_node: CanvasModulate
var is_light_on = false
var player_in_range = false


func _ready():
	if is_light_on:
		canvas_modulate_node.visible = false  # Disable modulate (lights ON)
		print("Lights ON: CanvasModulate DISABLED")
	else:
		canvas_modulate_node.visible = true   # Enable modulate (lights OFF)
		print("Lights OFF: CanvasModulate ENABLED")


# Called when the body enters the switch’s collision shape
func _on_Area2D_body_entered(body):
	print("Something entered:", body.name)  # Debug print
	if body.name == "Player":
		print("player detected")
		player_in_range = true

# Called when the body leaves the switch’s collision shape
func _on_Area2D_body_exited(body):
	if body.name == "Player":
		player_in_range = false

# If using the default input loop, this is one approach:
func _input(event):
	if player_in_range and event.is_action_pressed("light_switch"):
		_toggle_switch()
		

func _toggle_switch():
	# Flip the boolean
	is_light_on = not is_light_on
	
	# Instead of modifying color, enable/disable CanvasModulate
	if is_light_on:
		canvas_modulate_node.visible = false  # Disable modulate (lights ON)
		print("Lights ON: CanvasModulate DISABLED")
	else:
		canvas_modulate_node.visible = true   # Enable modulate (lights OFF)
		print("Lights OFF: CanvasModulate ENABLED")
	
	$AnimatedSprite2D.play("LightSwitch")
