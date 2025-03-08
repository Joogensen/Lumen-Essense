extends Area2D

@export var canvas_modulate_node: CanvasModulate
var is_light_on = false
var player_in_range = false

func _ready():
	canvas_modulate_node.visible = not is_light_on

func _on_Area2D_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_Area2D_body_exited(body):
	if body.name == "Player":
		player_in_range = false

func _input(event):
	if player_in_range and event.is_action_pressed("light_switch") and !is_light_on:
		_toggle_switch()

func _toggle_switch():
	is_light_on = !is_light_on
	canvas_modulate_node.visible = not is_light_on
	$AnimatedSprite2D.play("LightSwitch")
