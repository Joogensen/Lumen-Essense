extends CharacterBody2D

@export var orbit_radius: float = 64.0
@export var canvas_modulate_node: CanvasModulate
@export var light_switch: Area2D
@export var walk_speed = 150.0
@export_range(0,1) var acceleration = 0.1
@export_range(0,1) var deceleration = 0.1
@export var jump_force = -400
@export_range(0,1) var decelerate_on_jump_release = 0.5
@export var settings_scene: PackedScene

var can_move = true
var paranoia = 0.1
var paranoia_roi = 1.0
var is_dead = false
var can_burn_fuel = true

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
@onready var land_audio: AudioStreamPlayer2D = $PlayerAudios/Landing

const PUSH_FORCE = 18.0
const MIN_PUSH_FORCE = 10.0
var was_paranoia_zero = true
var was_on_floor = false

var base_heartbeat_pitch = 1.0
var max_heartbeat_pitch = 1.8
var base_heartbeat_volume_db = -10.0
var max_heartbeat_volume_db = 15.0
var base_whisper_volume_db = -20.0
var max_whisper_volume_db = 0.0

const LAND_VOLUME_MULTIPLIER = 0.5
const FOOTSTEP_VOLUME_MULTIPLIER = 5.0
const DEATH_VOLUME_MULTIPLIER = 2.0

var max_fall_speed_before_landing = 0.0
const FALL_DAMAGE_THRESHOLD = 750.0

var tries_left = 30

func _ready():
	if canvas_modulate_node == null:
		var canvas = get_tree().root.get_node_or_null("Main/CanvasModulate")
		if canvas:
			canvas_modulate_node = canvas
			print("✅ Found CanvasModulate at runtime!")
		else:
			print("❌ CanvasModulate still missing!")

	paranoia = 0
	paranoia_sprite.visible = false
	animated_sprite.stop()
	
	if settings_scene == null:
		settings_scene = preload("res://Scenes/SettingsLayer.tscn")

	for fuel in get_tree().get_nodes_in_group("lantern_fuel"):
		if fuel.has_signal("collected"):
			fuel.collected.connect(_on_fuel_collected)

	call_deferred("_connect_to_uv")


	if GameState.last_checkpoint_position != Vector2.ZERO:
		global_position = GameState.last_checkpoint_position
		var cam := $Camera2D
		cam.position_smoothing_enabled = false
		cam.global_position = global_position
		await get_tree().create_timer(0.1).timeout
		cam.position_smoothing_enabled = true

func _connect_to_uv():
	if tries_left <= 0:
		print("❌ Player could not find UV light after multiple tries.")
		return
	
	var uv = get_tree().root.get_node_or_null("Main/Player/PointLight2D")
	if uv and uv.has_signal("uv_active"):
		if not uv.uv_active.is_connected(_on_PointLight2D_uv_active):
			uv.uv_active.connect(_on_PointLight2D_uv_active)
		print("✅ Player connected to UV light!")
	else:
		tries_left -= 1
		call_deferred("_connect_to_uv") # Retry again next frame


func _process(delta):
	if is_dead: return

	light.visible = canvas_modulate_node and canvas_modulate_node.visible
	if light.visible:
		paranoia_check(delta)
		update_paranoia_animation(delta)

		if paranoia >= 5.0 and !is_dead:
			die()
	else:
		paranoia = 0
		paranoia_sprite.visible = false

	update_heartbeat_audio()

func _physics_process(delta: float) -> void:
	if !can_move: return
	
	#if velocity.y > 0:
		#max_fall_speed_before_landing = max(max_fall_speed_before_landing, velocity.y)


	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
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

	if is_on_floor() and !was_on_floor:
		#if abs(max_fall_speed_before_landing) > FALL_DAMAGE_THRESHOLD and not is_dead:
			#die()
		land_audio.pitch_scale = randf_range(0.9, 1.1)
		land_audio.volume_db = linear_to_db(SettingsManager.settings.master_volume * SettingsManager.settings.sfx_volume * LAND_VOLUME_MULTIPLIER)
		land_audio.play()

		#max_fall_speed_before_landing = 0.0


	was_on_floor = is_on_floor()

func paranoia_check(delta):
	if is_dead or not light.visible or not can_burn_fuel:
		return

	if $PointLight2D.is_lit and $PointLight2D.is_normal_mode:
		paranoia = max(0, paranoia - paranoia_roi * delta)
	else:
		paranoia = min(5, paranoia + paranoia_roi * delta)

func update_heartbeat_audio():
	var master_volume = SettingsManager.settings.master_volume
	var sfx_volume = SettingsManager.settings.sfx_volume
	var paranoia_factor = paranoia / 5.0

	if paranoia > 0:
		if not heartbeat.playing:
			heartbeat.play()
		if not whispers_audio.playing:
			whispers_audio.play()

		# Lerp dB first
		var heartbeat_db = lerp(base_heartbeat_volume_db, max_heartbeat_volume_db, paranoia_factor)
		var whispers_db = lerp(base_whisper_volume_db, max_whisper_volume_db, paranoia_factor)

		# Apply master and sfx scaling by ADDING dB (NOT using linear again)
		heartbeat.volume_db = heartbeat_db + linear_to_db(master_volume) + linear_to_db(sfx_volume)
		whispers_audio.volume_db = whispers_db + linear_to_db(master_volume) + linear_to_db(sfx_volume)

		heartbeat.pitch_scale = lerp(base_heartbeat_pitch, max_heartbeat_pitch, paranoia_factor)
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
	pickup_audio.volume_db = linear_to_db(SettingsManager.settings.master_volume * SettingsManager.settings.sfx_volume)
	pickup_audio.play()

func die():
	is_dead = true
	paranoia = 0
	GameState.is_player_dead = true

	pause_menu.accepting_input = false
	print("Player has died!")

	stop_all_sfx_except_death()

	if not dead_audio.playing:
		dead_audio.volume_db = linear_to_db(SettingsManager.settings.master_volume * SettingsManager.settings.sfx_volume * DEATH_VOLUME_MULTIPLIER)
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
	var base_volume = SettingsManager.settings.master_volume * SettingsManager.settings.sfx_volume * FOOTSTEP_VOLUME_MULTIPLIER
	footstep.volume_db = linear_to_db(base_volume) + randf_range(-1.5, 1.5)
	footstep.play()


func stop_all_sfx_except_death():
	if heartbeat.playing:
		heartbeat.stop()
	if footstep.playing:
		footstep.stop()
	if pickup_audio.playing:
		pickup_audio.stop()

func set_dialog_mode(active: bool):
	can_move = not active
	can_burn_fuel = not active
	walk_animation_player.stop()

	if active:
		print("Dialog mode: ON")
	else:
		print("Dialog mode: OFF")
