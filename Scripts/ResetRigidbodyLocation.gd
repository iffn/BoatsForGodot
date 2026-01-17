extends Node

@export var linked_rigidbody: RigidBody3D

var _original_position : Vector3
var _original_rotation : Vector3
var reset := false

func _ready() -> void:
	_original_position = linked_rigidbody.position
	_original_rotation = linked_rigidbody.rotation

func _physics_process(delta: float) -> void:
	if reset:
		linked_rigidbody.position = _original_position
		linked_rigidbody.rotation = _original_rotation
		
		linked_rigidbody.linear_velocity = Vector3.ZERO
		linked_rigidbody.angular_velocity = Vector3.ZERO
		reset = false

func reset_position():
	reset = true
