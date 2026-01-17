extends WaterLevelProvider
class_name SineWaveWaterLevelProvider

@export var water_material : ShaderMaterial

@export_group("Optional UI")
@export var height_slider : Slider
@export var freq_slider : Slider
@export var length_slider : Slider

var wave_height : float = 0.0
var wave_frequency : float = 1.0
var wave_length : float = 1.0

func _ready() -> void:
	# 1. Get initial values from shader
	wave_height = water_material.get_shader_parameter("wave_height")
	wave_frequency = water_material.get_shader_parameter("wave_frequency")
	wave_length = water_material.get_shader_parameter("wave_length")
	
	if height_slider:
		height_slider.value = wave_height
		height_slider.value_changed.connect(_on_height_changed)
		
	if freq_slider:
		freq_slider.value = wave_frequency
		freq_slider.value_changed.connect(_on_freq_changed)
		
	if length_slider:
		length_slider.value = wave_length
		length_slider.value_changed.connect(_on_length_changed)

# --- Signal Handlers ---

func _on_height_changed(value: float) -> void:
	wave_height = value
	water_material.set_shader_parameter("wave_height", value)

func _on_freq_changed(value: float) -> void:
	wave_frequency = value
	water_material.set_shader_parameter("wave_frequency", value)

func _on_length_changed(value: float) -> void:
	wave_length = value
	water_material.set_shader_parameter("wave_length", value)

# --- Core Logic ---

func get_distance_to_water(world_position : Vector3) -> float:
	var int_time : int
	int_time = Time.get_ticks_msec()
	
	# Add custom time value overrides for testing here
	
	var float_time = 0.001 * int_time
	water_material.set_shader_parameter("time", float_time)
	
	var water_pos_y := wave_height * sin(world_position.z / wave_length + float_time * wave_frequency)
	
	return world_position.y - water_pos_y
