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
@onready var walk_animation_player: AnimationPlayer = $WalkAnimationPlayer
@onready var light = $PointLight2D
@onready var animated_sprite = $AnimatedSprite2D  
@onready var footstep: AudioStreamPlayer2D = $PlayerAudios/Footstep


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
	
	if (velocity.length()>0.0 and is_on_floor()):
		walk_animation_player.play("walk")

	move_and_slide()
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

	# 🔥 If paranoia was previously 0 but now increasing, restart "paranoia"
	if was_paranoia_zero and paranoia > 0:
		animated_sprite.visible = true  # Show effect again
		animated_sprite.play("paranoia")  
		was_paranoia_zero = false  # Reset tracker

	if not animated_sprite.is_playing():
		animated_sprite.play()  # 🔥 If animation stops, restart it
	
# 🎯 Adjust FPS (Capped at 20, using an upward curve)
	var min_fps = 8.0  # 🔥 Lowest FPS when paranoia is low
	var max_fps = 24.0 # 🔥 Max FPS when paranoia is 5
	var fps_factor = pow(paranoia / 5.0, 1.2)  # Quadratic scaling for smooth speed-up
	var target_fps = min_fps + fps_factor * (max_fps - min_fps)  # 🔥 Scale FPS but cap at 20

	animated_sprite.speed_scale = target_fps / 14.0  # 🔥 Adjust animation speed based on FPS scaling

	# 🎯 Adjust Scale with an Exponential Curve (5.5 → 1.5 with an upward curve)
	var paranoia_factor = pow(paranoia / 5.0, 1.2)  # 🔥 Quadratic easing: small changes at first, bigger changes later
	var target_scale = 6.0 - paranoia_factor * (6.0 - 1.0)  # Scales downward with an upward curve
	animated_sprite.scale = animated_sprite.scale.lerp(Vector2(target_scale, target_scale), delta * 15.0)

	# 🎯 Adjust Transparency with an Exponential Curve
	var target_alpha = 0.2 + pow(paranoia / 5.0, 1.2) * (1.0 - 0.2)  # More transparent at low paranoia, solid at high
	animated_sprite.modulate = animated_sprite.modulate.lerp(Color(1.0, 0.0, 0.0, target_alpha), delta * 15.0)  # 🔥 Faster transparency transition
