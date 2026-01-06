extends Node3D

class_name BoatThruster

@export var engine_thrust : float
@export var engine_rotation_deg : float
@export var engine_pitch_deg : float

@export var input_forward : InputResource
@export var input_backward : InputResource
@export var input_right : InputResource
@export var input_left : InputResource

@export var linked_rigidbody : RigidBody3D

@export var keyboard_inputs := true
@export var joystick_inputs := false

var throttle_initialized = 0

var external_control := false
var external_throttle := 0.0
var external_steering := 0.0
var external_trimming := 0.0

func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var steering := 0.0
	var trimming := 0.0
	
	if external_control:
		throttle = external_throttle
		steering = external_steering
		trimming = external_trimming
		
	elif joystick_inputs:
		trimming = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		steering = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		
		if throttle_initialized:
			throttle = -Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) * 0.5 + 0.5
		else:
			throttle_initialized = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) != 0.0
		
	elif keyboard_inputs:
		if Input.is_action_pressed(input_forward.input_name):
			throttle = 1.0
		
		if Input.is_action_pressed(input_backward.input_name):
			throttle = -1.0
		
		if Input.is_action_pressed(input_right.input_name):
			steering = 1.0
		
		if Input.is_action_pressed(input_left.input_name):
			steering = -1.0
	
	var thrust = engine_thrust * throttle
	
	rotation = Vector3(deg_to_rad(trimming * engine_pitch_deg),  deg_to_rad(steering * engine_rotation_deg), 0)
	
	var thrust_force_global := global_transform.basis * Basis.from_euler(rotation) * Vector3(0, 0, -thrust)
	var application_position = global_position - linked_rigidbody.global_position
	linked_rigidbody.apply_force(thrust_force_global, application_position)
