extends WaterLevelProvider

class_name SineWaveWaterLevelProvider

@export var water_material : ShaderMaterial

var wave_height : float = 0.0
var wave_frequency : float = 1.0
var wave_length : float = 1.0

func _ready() -> void:
	wave_height = water_material.get_shader_parameter("wave_height")
	wave_frequency = water_material.get_shader_parameter("wave_frequency")
	wave_length = water_material.get_shader_parameter("wave_length")
	
	print("wave_height: ", wave_height)
	print("wave_frequency: ", wave_frequency)
	print("wave_length: ", wave_length)

func get_distance_to_water(world_position : Vector3) -> float:
	var time : int
	time = 25443 # broken cube
	time = 96409 # broken cube
	time = 7284 # broken speed boat
	time = 6884 # broken speed boat
	time = 5353 # broken plane
	time = Time.get_ticks_msec()
	
	var float_time = 0.001 * time
	water_material.set_shader_parameter("time", float_time)
	
	var water_pos_y := wave_height * sin(world_position.z / wave_length + float_time * wave_frequency)
	
	return world_position.y - water_pos_y
	
