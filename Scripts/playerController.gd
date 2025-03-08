extends CharacterBody2D

@export var canvas_modulate_node: CanvasModulate  
@export var walk_speed = 150.0
@export_range(0,1) var acceleration = 0.1
@export_range(0,1) var deceleration = 0.1
@export var jump_force = -400
@export_range(0,1) var decelerate_on_jump_release = 0.5

var can_move = true
var paranoia = 0.0
var paranoia_roi = 1.0
var is_dead = false

@onready var walk_animation_player: AnimationPlayer = $WalkAnimationPlayer
@onready var light = $PointLight2D
@onready var paranoia_sprite = $SpriteParanoia
@onready var animated_sprite = $ParanoiaAnimationPlayer
@onready var footstep: AudioStreamPlayer2D = $PlayerAudios/Footstep

const PUSH_FORCE = 18.0
const MIN_PUSH_FORCE = 10.0

func _ready():
	for fuel in get_tree().get_nodes_in_group("lantern_fuel"):
		if fuel.has_signal("collected"):  
			fuel.collected.connect(_on_fuel_collected)

func _process(delta):
	if is_dead: return

	light.visible = canvas_modulate_node and canvas_modulate_node.visible
	if light.visible: 
		paranoia_check(delta)
		update_paranoia_animation(delta)
	else:
		paranoia = 0  
		paranoia_sprite.visible = false  

	if paranoia >= 5.0:
		die()

func _on_fuel_collected():
	light.refuel(50)

func _physics_process(delta: float) -> void:
	if !can_move: return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_wall()):
		velocity.y = jump_force
	elif Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release
	
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * walk_speed, walk_speed * acceleration)
		$SpritePlayer.flip_h = (direction < 0)  
		$PointLight2D.position.x = abs($PointLight2D.position.x) * (-1 if direction < 0 else 1)
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed * deceleration)
	if is_on_floor():
		if direction:
			walk_animation_player.play("walk")
		else:
			walk_animation_player.stop()
	else:
		walk_animation_player.stop()

	move_and_slide()

	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D and is_on_floor():
			c.get_collider().apply_central_impulse(-c.get_normal() * ((PUSH_FORCE * velocity.length() / walk_speed) + MIN_PUSH_FORCE))

func _play_footstep_audio():
	footstep.pitch_scale = randf_range(.8,1.2)
	footstep.play()

func die():
	print("Player has died!")
	hide()
	disable_input()
	await get_tree().create_timer(5.0).timeout  
	get_tree().reload_current_scene()  
	enable_input()
	is_dead = true

func disable_input():
	can_move = false  

func enable_input():
	can_move = true  

func paranoia_check(delta):
	if is_dead or not light.visible: return

	paranoia = max(0, paranoia - paranoia_roi * delta) if $PointLight2D.is_lit and $PointLight2D.is_normal_mode else min(5, paranoia + paranoia_roi * delta)
	print("Paranoia:", paranoia)

var was_paranoia_zero = true  

func update_paranoia_animation(delta):
	if paranoia == 0:
		animated_sprite.stop()  # Stop the paranoia animation
		paranoia_sprite.visible = false  # Hide the paranoia sprite
		was_paranoia_zero = true
		return  

	if was_paranoia_zero and paranoia > 0:
		paranoia_sprite.visible = true  # Make the paranoia effect visible
		animated_sprite.play("Paranoia")  
		was_paranoia_zero = false  

	if not animated_sprite.is_playing():
		animated_sprite.play()

	# Smooth speed scaling based on paranoia
	var min_fps = 10.0
	var max_fps = 24.0
	var paranoia_factor = pow(paranoia / 5.0, 1.2)  
	var target_fps = min_fps + paranoia_factor * (max_fps - min_fps)  
	animated_sprite.speed_scale = target_fps / min_fps  

	# Apply transformations to paranoia_sprite, NOT animated_sprite
	paranoia_sprite.scale = paranoia_sprite.scale.lerp(Vector2(6.0 - paranoia_factor * 5.0, 6.0 - paranoia_factor * 5.0), delta * 15.0)
	paranoia_sprite.modulate = paranoia_sprite.modulate.lerp(Color(1.0, 0.0, 0.0, 0.2 + paranoia_factor * 0.8), delta * 15.0)
