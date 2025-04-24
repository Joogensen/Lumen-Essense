extends PointLight2D
var max_fuel = 100.0
@export var current_fuel = 100.0
var fuel_burn_rate = 1.0
var is_lit = true


@export var canvas_modulate_node: CanvasModulate  # Reference to main light modulate

@onready var flicker_timer = Timer.new()
@onready var light = self
#sounds

@onready var switch_light_audio: AudioStreamPlayer2D = $switch_light_audio
@onready var uv_light_audio: AudioStreamPlayer2D = $uv_light_audio
@onready var normal_light_audio: AudioStreamPlayer2D = $normal_light_audio


signal uv_active

var parent = get_parent()

var light_colors = [
	Color(1.0, 0.9, 0.6),  # White (default, fuel burns)
	Color(1, 0, 1),  # Purple
]

var current_color_index = 0  # Start with white light
var is_normal_mode = true  # True = Fuel burns, False = Free color mode

func _ready():
	self.visible = true
	flicker_timer.wait_time = 0.1
	flicker_timer.connect("timeout", Callable(self, "_on_FlickerTimer_timeout"))
	add_child(flicker_timer)  

	self.color = light_colors[current_color_index]
		
	if !GameState.is_player_dead:
		_play_normal_light_audio()


func _on_battery_collected():
	refuel(50)  # Increase fuel when a battery is collected

func refuel(amount):
	current_fuel += amount
	if current_fuel > max_fuel:
		current_fuel = max_fuel
	is_lit = true  # Relight the lantern if it was off
	light.visible = true
	print("Battery collected! Fuel increased to: ", current_fuel)

func _process(delta):
	if not canvas_modulate_node:
		print("❌ CanvasModulate is missing!")
		return

	if GameState.is_in_dialog:
		print("🛑 Skipping fuel burn due to dialog")
		return

	var is_light_on = not canvas_modulate_node.visible
	print("CanvasModulate.visible =", canvas_modulate_node.visible)
	print("is_light_on =", is_light_on)

	if is_light_on:
		print("🌞 World is lit — skipping fuel burn")
		return

	if is_lit and is_normal_mode:
		print("🔥 Fuel Level:", round(current_fuel), "/", max_fuel)
		consume_fuel(delta)
	else:
		print("🚫 Not lit or not in normal mode — no fuel burn")


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
	light.visible = false
	
func _input(event):
	#if event.is_action_pressed("toggle_lantern") and current_fuel > 0:
		#is_lit = !is_lit
		#self.visible = is_lit

	if event.is_action_pressed("change_light_color"):
		cycle_light_color()

func cycle_light_color():
	current_color_index = (current_color_index + 1) % light_colors.size()
	self.color = light_colors[current_color_index]  

	_play_switch_light_audio()

	# If switching **back** to normal (white) mode, fuel burns again
	if current_color_index == 0:
		is_normal_mode = true
		uv_active.emit(false)
		_play_normal_light_audio()
	else:
		is_normal_mode = false  # If it's a colored light, stop fuel burning
		uv_active.emit(true)  # Emit the signal when the uv is active
		_play_uv_light_audio()
		#Player._play_paranoia_audio() #calls player function to play paranoia


func _play_normal_light_audio():
	if GameState.is_player_dead:
		return
	normal_light_audio.play()

func _play_uv_light_audio():
	if GameState.is_player_dead:
		return
	uv_light_audio.play()

func _play_switch_light_audio():
	if GameState.is_player_dead:
		return
	switch_light_audio.play()
	uv_light_audio.stop()
	normal_light_audio.stop()
