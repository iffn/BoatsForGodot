extends Node

@export var steering_slider : Slider
@export var steering_number : SpinBox
@export var throttle_slider : Slider
@export var throttle_number : SpinBox
@export var trim_slider : Slider
@export var trim_number : SpinBox

@export var boat_view : BoatView
var calculation_boat : BoatController:
	get:
		return boat_view.linked_boat

func enabled(value: bool):
	for thruster in calculation_boat.thrusters:
		thruster.external_control = value
	
	if value:
		set_steering(steering_slider.value)
		set_throttle(throttle_slider.value)
		set_trim(trim_slider.value)

func set_steering(steering: float):
	for thruster in calculation_boat.thrusters:
		thruster.external_steering = steering
	steering_slider.set_value_no_signal(steering)
	steering_number.set_value_no_signal(steering)

func set_throttle(throttle: float):
	for thruster in calculation_boat.thrusters:
		thruster.external_throttle = throttle
	throttle_slider.set_value_no_signal(throttle)
	throttle_number.set_value_no_signal(throttle)

func set_trim(trim: float):
	for thruster in calculation_boat.thrusters:
		thruster.external_trimming = trim
	trim_slider.set_value_no_signal(trim)
	trim_number.set_value_no_signal(trim)
