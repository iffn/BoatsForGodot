extends Node

@export var steering_slider : Slider
@export var steering_number : SpinBox
@export var throttle_slider : Slider
@export var throttle_number : SpinBox
@export var trim_slider : Slider
@export var trim_number : SpinBox

@export var linked_boat : BoatController

@export var _enabled := true
@export var _update_from_inputs := true

func _process(delta: float) -> void:
	
	if _update_from_inputs && linked_boat.thrusters.size() > 0:
		
		var reference_thruster := linked_boat.thrusters[0]
		#print(reference_thruster.can_process())
		#reference_thruster._process(delta)
		
		if steering_slider:
			steering_slider.set_value_no_signal(reference_thruster.steering)
		if steering_number:
			steering_number.set_value_no_signal(reference_thruster.steering)
		
		if throttle_slider:
			throttle_slider.set_value_no_signal(reference_thruster.throttle)
		if throttle_number:
			throttle_number.set_value_no_signal(reference_thruster.throttle)
		
		if trim_slider:
			trim_slider.set_value_no_signal(reference_thruster.trimming)
		if throttle_number:
			throttle_number.set_value_no_signal(reference_thruster.trimming)

func enable(value: bool):
	_enabled = value
	_update_from_inputs = value
	
	if value:
		if steering_slider:
			set_steering(steering_slider.value)
		elif steering_number:
			set_steering(steering_number.value)
		
		if throttle_slider:
			set_throttle(throttle_slider.value)
		elif throttle_number:
			set_throttle(throttle_number.value)
		
		if trim_slider:
			set_steering(trim_slider.value)
		elif trim_number:
			set_steering(trim_number.value)
	else:
		for thruster in linked_boat.thrusters:
			thruster.throttle = 0
			thruster.steering = 0
			thruster.trimming = 0

func set_steering(steering: float):
	if _enabled:
		for thruster in linked_boat.thrusters:
			thruster.steering = steering
	
	if steering_slider:
		steering_slider.set_value_no_signal(steering)
	if steering_number:
		steering_number.set_value_no_signal(steering)

func set_throttle(throttle: float):
	if _enabled:
		for thruster in linked_boat.thrusters:
			thruster.throttle = throttle
	
	if throttle_slider:
		throttle_slider.set_value_no_signal(throttle)
	if throttle_number:
		throttle_number.set_value_no_signal(throttle)

func set_trim(trim: float):
	if _enabled:
		for thruster in linked_boat.thrusters:
			thruster.trimming = trim
	
	if trim_slider:
		trim_slider.set_value_no_signal(trim)
	if throttle_number:
		throttle_number.set_value_no_signal(trim)
