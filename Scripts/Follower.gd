extends Node3D

class_name Follower

@export var target : Node3D 

@export var follow_horizontal_position : bool
@export var follow_vertical_position : bool
@export var follow_heading : bool
@export var follow_pitch_and_roll : bool

var _initial_position_offset : Vector3
var _initial_rotation_offset : Vector3

func setup(the_target : Node3D):
	target = the_target
	_initial_position_offset = global_position - target.global_position
	_initial_rotation_offset = global_rotation - target.global_rotation

func _ready() -> void:
	if target:
		setup(target)

func _process(delta: float) -> void:
	if !target:
		return
	
	if follow_horizontal_position:
		global_position.x = target.global_position.x + _initial_position_offset.x
		global_position.z = target.global_position.z + _initial_position_offset.z
	if follow_vertical_position:
		global_position.y = target.global_position.y + _initial_position_offset.y
	if follow_heading:
		global_rotation.y = target.global_rotation.y + _initial_rotation_offset.y
	if follow_pitch_and_roll:
		global_rotation.x = target.global_rotation.x + _initial_rotation_offset.x
		global_rotation.z = target.global_rotation.z + _initial_rotation_offset.z
