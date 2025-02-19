extends CharacterBody2D

@export var walk_speed = 150.0
@export_range(0,1) var acceleration = 0.1
@export_range(0,1) var deceleration = 0.1

@export var jump_force = -400
@export_range(0,1) var decelerate_on_jump_release = 0.5
var can_move = true

@onready var light = $PointLight2D

func _ready():
	var lantern_fuel = get_tree().get_nodes_in_group("lantern_fuel")
	for fuel in lantern_fuel:
		if fuel.has_signal("collected"):  
			fuel.collected.connect(_on_fuel_collected)
			
	

func _on_fuel_collected():
	light.refuel(50)  # Call Light's refuel function

func _physics_process(delta: float) -> void:
	if !can_move:
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_wall()):
		velocity.y = jump_force
	
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * walk_speed, walk_speed * acceleration)
		$Sprite2D.flip_h = (direction > 0)  
		$PointLight2D.position.x = abs($PointLight2D.position.x) * (-1 if direction < 0 else 1)

	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed * deceleration)
	move_and_slide()

func die():
	print("Player has died!")
	# Example actions: Hide player, play animation, restart level
	hide()  # Hide the player before respawning
	disable_input()
	
	await get_tree().create_timer(5.0).timeout  # Wait 1 second
	get_tree().reload_current_scene()  # Restart the level
	enable_input()

func disable_input():
	can_move = false  # Stops listening to input

func enable_input():
	can_move = true  # Stops listening to input	
