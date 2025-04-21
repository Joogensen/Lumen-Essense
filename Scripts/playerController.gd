extends CharacterBody2D

@export var orbit_radius: float = 64.0
@export var canvas_modulate_node: CanvasModulate  
@export var light_switch: Area2D
@export var walk_speed = 150.0
@export_range(0,1) var acceleration = 0.1
@export_range(0,1) var deceleration = 0.1
@export var jump_force = -400
@export_range(0,1) var decelerate_on_jump_release = 0.5

var can_move = true
var paranoia = 0.1
var paranoia_roi = 1.0
var is_dead = false

@onready var walk_animation_player: AnimationPlayer = $WalkAnimationPlayer
@onready var light: PointLight2D = $PointLight2D
@onready var paranoia_sprite = $SpriteParanoia
@onready var animated_sprite = $ParanoiaAnimationPlayer
@onready var footstep: AudioStreamPlayer2D = $PlayerAudios/Footstep
@onready var heartbeat: AudioStreamPlayer2D = $PlayerAudios/Heartbeat
@onready var dead_audio: AudioStreamPlayer2D = $PlayerAudios/DeadAudio
@onready var pickup_audio: AudioStreamPlayer2D = $PlayerAudios/PickupAudio
@onready var death_screen: CanvasLayer = $DeathScreen
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var whispers_audio: AudioStreamPlayer2D = $PlayerAudios/Whispers


const PUSH_FORCE = 18.0
const MIN_PUSH_FORCE = 10.0
var was_paranoia_zero = true  

# Heartbeat scaling parameters
var base_heartbeat_pitch = 1.0
var max_heartbeat_pitch = 1.8
var base_heartbeat_volume_db = -30.0
var max_heartbeat_volume_db = -6.0

var base_whisper_volume_db = -40.0  # fully silent
var max_whisper_volume_db = -8.0    # loud at full paranoia


func _ready():
	paranoia = 0
	paranoia_sprite.visible = false
	animated_sprite.stop()
	

	for fuel in get_tree().get_nodes_in_group("lantern_fuel"):
		if fuel.has_signal("collected"):
			fuel.collected.connect(_on_fuel_collected)

	var uv = get_tree().root.get_node("Main/Player/PointLight2D")
	if uv and uv.has_signal("uv_active"):
		uv.uv_active.connect(_on_PointLight2D_uv_active)

func _process(delta):
	if is_dead: return

	light.visible = canvas_modulate_node and canvas_modulate_node.visible
	if light.visible:
		paranoia_check(delta)
		update_paranoia_animation(delta)
		
		print("Paranoia:", paranoia)
	
		if paranoia >= 5.0 and !is_dead:
			die()
	else:
		paranoia = 0
		paranoia_sprite.visible = false

	update_heartbeat_audio()


func _physics_process(delta: float) -> void:
	if !can_move: return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and (is_on_floor()):
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

	if $Arrow.visible and light_switch:
		var arrow_direction = light_switch.global_position - global_position
		$Arrow.position = arrow_direction.normalized() * orbit_radius
		$Arrow.rotation = arrow_direction.angle()
		if arrow_direction.length() < 100.0:
			$Arrow.visible = false
		else:
			$Arrow.visible = true

func paranoia_check(delta):
	if is_dead or not light.visible: return

	if $PointLight2D.is_lit and $PointLight2D.is_normal_mode:
		paranoia = max(0, paranoia - paranoia_roi * delta)
	else:
		paranoia = min(5, paranoia + paranoia_roi * delta)

func update_heartbeat_audio():
	if paranoia > 0:
		if !heartbeat.playing:
			heartbeat.play()
		if !whispers_audio.playing:
			whispers_audio.play()

# Fade volume based on paranoia level (0 to 5)
		var whisper_volume = lerp(base_whisper_volume_db, max_whisper_volume_db, paranoia / 5.0)
		whispers_audio.volume_db = whisper_volume


		var pitch = lerp(base_heartbeat_pitch, max_heartbeat_pitch, paranoia / 5.0)
		heartbeat.pitch_scale = pitch

		var volume_db = lerp(base_heartbeat_volume_db, max_heartbeat_volume_db, paranoia / 5.0)
		heartbeat.volume_db = volume_db
	else:
		if heartbeat.playing:
			heartbeat.stop()
		if whispers_audio.playing:
			whispers_audio.stop()


func update_paranoia_animation(delta):
	if paranoia == 0:
		animated_sprite.stop()
		paranoia_sprite.visible = false
		was_paranoia_zero = true
		return

	if was_paranoia_zero and paranoia > 0:
		paranoia_sprite.visible = true
		animated_sprite.play("Paranoia")
		was_paranoia_zero = false

	if not animated_sprite.is_playing():
		animated_sprite.play()

	var min_fps = 10.0
	var max_fps = 24.0
	var paranoia_factor = pow(paranoia / 5.0, 1.2)
	var target_fps = min_fps + paranoia_factor * (max_fps - min_fps)
	animated_sprite.speed_scale = target_fps / min_fps

	paranoia_sprite.scale = paranoia_sprite.scale.lerp(Vector2(6.0 - paranoia_factor * 5.0, 6.0 - paranoia_factor * 5.0), delta * 15.0)
	paranoia_sprite.modulate = paranoia_sprite.modulate.lerp(Color(1.0, 0.0, 0.0, 0.2 + paranoia_factor * 0.8), delta * 15.0)

func _on_fuel_collected():
	light.refuel(50)
	pickup_audio.play()

func die():
	is_dead = true
	paranoia = 0
	GameState.is_player_dead = true

	pause_menu.accepting_input = false
	print("Player has died!")

	stop_all_sfx_except_death()

	if not dead_audio.playing:
		dead_audio.play()

	hide()
	disable_input()

	await get_tree().process_frame  
	death_screen.start_animation()

	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()


	
func disable_input():
	can_move = false

func enable_input():
	can_move = true

func _on_PointLight2D_uv_active(is_uv_active: bool) -> void:
	$Arrow.visible = is_uv_active
	
func _play_footstep_audio():
	footstep.pitch_scale = randf_range(0.8, 1.2)
	footstep.play()
	
func stop_all_sfx_except_death():
	if heartbeat.playing:
		heartbeat.stop()
	if footstep.playing:
		footstep.stop()
	if pickup_audio.playing:
		pickup_audio.stop()
