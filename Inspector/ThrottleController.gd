extends Node

@export var boat_view : BoatView
var calculation_boat : BoatController:
	get:
		return boat_view.linked_boat

func enabled(value: bool):
	for thruster in calculation_boat.thrusters:
		thruster.external_control = value

func set_throttle(throttle: float):
	for thruster in calculation_boat.thrusters:
		thruster.external_throttle = throttle
