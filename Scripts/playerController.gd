extends CharacterBody2D

@export var walk_speed = 150.0
@export_range(0,1) var acceleration = 0.1
@export_range(0,1) var deceleration = 0.1

@export var jump_force = -400
@export_range(0,1) var decelerate_on_jump_release = 0.5
var can_move = true

var paranoia = 0.0
var paranoia_roi = 1.0
var is_dead = false
var current_frame = 15  # Start at blank frame

@onready var light = $PointLight2D
@onready var animated_sprite = $AnimatedSprite2D  

func _ready():
	var lantern_fuel = get_tree().get_nodes_in_group("lantern_fuel")
	for fuel in lantern_fuel:
		if fuel.has_signal("collected"):  
			fuel.collected.connect(_on_fuel_collected)


func _process(delta):
	if is_dead: 
		return
	paranoia_check(delta)  
	update_paranoia_animation(delta)  # 🔥 Now using delta for smooth movement

	if paranoia >= 5.0:
		is_dead = true 
		die()
	print("Process running")

func _on_fuel_collected():
	light.refuel(50)  # Call Light's refuel function

func _physics_process(delta: float) -> void:
	if !can_move:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_wall()):
		velocity.y = jump_force

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release

	# Handle movement input.
	var direction := Input.get_axis("left", "right")

	if direction:
		velocity.x = move_toward(velocity.x, direction * walk_speed, walk_speed * acceleration)
		$Sprite2D.flip_h = (direction < 0)  
		$PointLight2D.position.x = abs($PointLight2D.position.x) * (-1 if direction < 0 else 1)
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed * deceleration)

	move_and_slide()

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
	if is_dead:
		return

	var is_lit = $PointLight2D.is_lit
	var is_normal_mode = $PointLight2D.is_normal_mode

	if is_lit and is_normal_mode:
		paranoia -= paranoia_roi * delta
		paranoia = max(paranoia, 0)
	else:
		paranoia += paranoia_roi * delta
		paranoia = min(paranoia, 5) 
	print("Paranoia:", paranoia)  # 🔥 Debugging print

var was_paranoia_zero = true  # 🔥 Tracks if paranoia was at 0

func update_paranoia_animation(delta):
	if paranoia == 0:
		animated_sprite.stop()  # Pause animation
		animated_sprite.visible = false  # 🔥 Hide the effect completely
		was_paranoia_zero = true  # 🔥 Remember that paranoia was at zero
		return  

	# 🔥 If paranoia was previously 0 but now increasing, restart "paranoia_low"
	if was_paranoia_zero and paranoia > 0:
		animated_sprite.visible = true  # Show effect again
		animated_sprite.play("paranoia_low")  
		was_paranoia_zero = false  # Reset tracker

	if not animated_sprite.is_playing():
		animated_sprite.play()  # 🔥 If animation stops, restart it

	# Get the total number of frames for each animation
	var last_frame = 6  # All animations have 7 frames (0-6)

	# 🎬 Choose the right animation based on paranoia level
	if paranoia < 2.5:
		if animated_sprite.animation != "paranoia_low":
			animated_sprite.play("paranoia_low")  
		elif animated_sprite.frame == last_frame:
			animated_sprite.play("paranoia_low")  # 🔥 Ensure it loops

	elif paranoia >= 2.5 and paranoia < 5:
		if animated_sprite.animation == "paranoia_low" and animated_sprite.frame == last_frame:
			animated_sprite.play("paranoia_high")  # 🔥 Switch only when "paranoia_low" finishes
		elif animated_sprite.animation != "paranoia_high":
			animated_sprite.play("paranoia_high")  

	else:  # If paranoia is decreasing (5 → 0)
		if animated_sprite.animation == "paranoia_high" and animated_sprite.frame == last_frame:
			animated_sprite.play("paranoia_decrease")  # 🔥 Switch only when "paranoia_high" finishes
		elif animated_sprite.animation != "paranoia_decrease":
			animated_sprite.play("paranoia_decrease")  

	# 🎯 Dynamically Adjust FPS Based on Paranoia Level
	animated_sprite.speed_scale = 2 + (paranoia * 0.5)  # Adjust speed dynamically

	# 🎯 Adjust Scale (Smoothly Shrinking from 5.5 → 1.5)
	var target_scale = 5.5 - (paranoia / 5.0) * (5.5 - 1.1)
	animated_sprite.scale += (Vector2(target_scale, target_scale) - animated_sprite.scale) * delta * 10.0
	
	# 🎯 Adjust Transparency (More transparent when paranoia is low, fully visible at paranoia 5)
	var target_alpha = 0.2 + (paranoia / 5.0) * (1.0 - 0.2)  # Min 0.2 (almost transparent), Max 1.0 (fully visible)
	animated_sprite.modulate = animated_sprite.modulate.lerp(Color(1.0, 0.0, 0.0, target_alpha), delta * 15.0)  # 🔥 Faster transparency transition
