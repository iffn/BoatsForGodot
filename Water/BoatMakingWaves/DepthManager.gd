@tool
extends Node

@export var cam_far: float = 3:
	set(value):
		cam_far = value
		depth_display.set_shader_parameter("cam_far", cam_far)
		camera.far = cam_far

@export var width: float = 3:
	set(value):
		width = value
		camera.size = width
		depth_quad.scale = width * Vector3.ONE

@export_tool_button("Apply just in case", "") var button_function = apply_parameters

@export var camera: Camera3D
@export var subviewport: SubViewport
@export var depth_quad: Node3D
@export var depth_display: ShaderMaterial

func apply_parameters():
	depth_display.set_shader_parameter("cam_far", cam_far)
	
	camera.far = cam_far
	camera.size = width
	
	depth_quad.scale = width * Vector3.ONE
	
	print("Parameters applied")

func _ready() -> void:
	apply_parameters()
