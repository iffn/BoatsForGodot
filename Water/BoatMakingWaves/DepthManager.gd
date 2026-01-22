extends Node3D

@export var simulation_shader : ShaderMaterial
@export var depth_camera : Camera3D
@export var reference_boat : Node3D
@export var water_quad : Node3D
@export var resolution := 512
@export var size := 100.0
@export var should_update_position := true

var pixels_per_unit : float

func apply_parameters():
	
	depth_camera.size = size
	
	pixels_per_unit = float(resolution) / float(size)

func _ready() -> void:
	simulation_shader.set_shader_parameter("initializationFactor", 1)
	apply_parameters()
	
	for i in range(5):
		await get_tree().process_frame
	simulation_shader.set_shader_parameter("initializationFactor", 0)

func _process(_delta: float) -> void:
	if(should_update_position):
		update_position()

func update_position(): 
	var displacement := reference_boat.global_position - global_position
	
	var offset_x : int = int(round(displacement.x * pixels_per_unit))
	var offset_z : int = int(round(displacement.z * pixels_per_unit))
	
	if offset_x != 0 or offset_z != 0:
		var snapped_world_move = Vector3(
			offset_x / pixels_per_unit,
			0.0,
			offset_z / pixels_per_unit
		)
		
		global_position += snapped_world_move
		
		depth_camera.global_position.x = global_position.x
		depth_camera.global_position.z = global_position.z
		
		simulation_shader.set_shader_parameter("offsetX", offset_x)
		simulation_shader.set_shader_parameter("offsetY", offset_z)
		
	else:
		simulation_shader.set_shader_parameter("offsetX", 0)
		simulation_shader.set_shader_parameter("offsetY", 0)
