extends PointLight2D

var light_colors = [
	Color(1, 1, 1),  # White (default, fuel burns)
	Color(1, 0, 1),  # Purple
]

var current_color_index = 0  # Start with white light
var is_normal_mode = true  # True = Fuel burns, False = Free color mode

var max_fuel = 100.0  # Maximum fuel capacity
@export var current_fuel = 100.0  # Start with a full tank
var fuel_burn_rate = 1.0  # Fuel consumption per second
var is_lit = true  # Whether the lantern is on

@onready var flicker_timer = Timer.new()
@onready var light = self  

func _ready():
	self.visible = true  # Ensure the light starts on
	flicker_timer.wait_time = 0.1  
	flicker_timer.connect("timeout", Callable(self, "_on_FlickerTimer_timeout"))
	add_child(flicker_timer)  

func _process(delta):
	if is_lit and is_normal_mode:
		consume_fuel(delta)
		print("Fuel Level: ", current_fuel)


func consume_fuel(delta):
	current_fuel -= fuel_burn_rate * delta  
	if current_fuel <= 0:
		current_fuel = 0
		turn_off_lantern()
	elif current_fuel <= max_fuel * 0.2:
		if flicker_timer.is_stopped():
			flicker_timer.start()
	else:
		flicker_timer.stop()
		self.energy = 1.5  

func _on_FlickerTimer_timeout():
	if current_fuel <= (max_fuel * 0.2):
		self.energy = randf_range(0.5, 1.5)  

func turn_off_lantern():
	is_lit = false
	light.visible = false  # Hide the light when fuel runs out

func refuel(amount):
	current_fuel += amount
	if current_fuel > max_fuel:
		current_fuel = max_fuel
	is_lit = true  # Relight the lantern if it was off
	light.visible = true

func _input(event):
	if event.is_action_pressed("toggle_lantern") and current_fuel > 0:
		is_lit = !is_lit
		self.visible = is_lit

	if event.is_action_pressed("change_light_color"):
		cycle_light_color()

func cycle_light_color():
	current_color_index = (current_color_index + 1) % light_colors.size()
	self.color = light_colors[current_color_index]  

	# If switching **back** to normal (white) mode, fuel burns again
	if current_color_index == 0:
		is_normal_mode = true
	else:
		is_normal_mode = false  # If it's a colored light, stop fuel burning
