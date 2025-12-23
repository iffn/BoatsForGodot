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

@export var thrust_output : Label

@export var keyboard_inputs := true
@export var joystick_inputs := false

var throttle_initialized = 0



func _physics_process(delta: float) -> void:
	var thrust := 0.0
	var rotation_deg := 0.0
	var pitch_deg := 0.0
	
	if(joystick_inputs):
		var pitch_up_pos := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		var roll_right_pos := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		var throttle := 0.0
		
		if throttle_initialized:
			throttle = -Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) * 0.5 + 0.5
		else:
			throttle_initialized = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) != 0.0
		thrust = engine_thrust * throttle
		rotation_deg = roll_right_pos * engine_rotation_deg
		pitch_deg = -pitch_up_pos * engine_pitch_deg
	
	if keyboard_inputs:
		if Input.is_action_pressed(input_forward.input_name):
			thrust = engine_thrust
		
		if Input.is_action_pressed(input_backward.input_name):
			thrust = -engine_thrust
		
		if Input.is_action_pressed(input_right.input_name):
			rotation_deg = engine_rotation_deg
		
		if Input.is_action_pressed(input_left.input_name):
			rotation_deg = -engine_rotation_deg
	
	rotation = Vector3(deg_to_rad(pitch_deg),  deg_to_rad(rotation_deg), 0)
	
	var thrust_force_global := global_transform.basis * Basis.from_euler(rotation) * Vector3(0, 0, -thrust)
	var application_position = global_position - linked_rigidbody.global_position
	linked_rigidbody.apply_force(thrust_force_global, application_position)
	
	if thrust_output:
		thrust_output.text = "Thrust: " + str(thrust)
	
