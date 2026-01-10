extends Node

@export var steering_slider : Slider
@export var steering_number : SpinBox
@export var throttle_slider : Slider
@export var throttle_number : SpinBox
@export var trim_slider : Slider
@export var trim_number : SpinBox

@export var linked_boat : BoatController

@export var _enabled := true

func enable(value: bool):
	_enabled = value
	
	for thruster in linked_boat.thrusters:
		thruster.external_control = value
	
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
			thruster.external_throttle = 0
			thruster.external_steering = 0
			thruster.external_trimming = 0

func set_steering(steering: float):
	if _enabled:
		for thruster in linked_boat.thrusters:
			thruster.external_steering = steering
	
	if steering_slider:
		steering_slider.set_value_no_signal(steering)
	if steering_number:
		steering_number.set_value_no_signal(steering)

func set_throttle(throttle: float):
	if _enabled:
		for thruster in linked_boat.thrusters:
			thruster.external_throttle = throttle
	
	if throttle_slider:
		throttle_slider.set_value_no_signal(throttle)
	if throttle_number:
		throttle_number.set_value_no_signal(throttle)

func set_trim(trim: float):
	if _enabled:
		for thruster in linked_boat.thrusters:
			thruster.external_trimming = trim
	
	if trim_slider:
		trim_slider.set_value_no_signal(trim)
	if throttle_number:
		throttle_number.set_value_no_signal(trim)
