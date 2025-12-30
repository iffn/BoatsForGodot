extends Node

class_name CenterEvaluator

@export var calculation_boat : BoatController
@export var center_of_mass_indicator : Node3D
@export var center_of_buoyancy_indicator : Node3D

func update_centers():
	var data := calculation_boat.hull.calculate_all()
	
	center_of_mass_indicator.global_position = calculation_boat.global_transform * calculation_boat.center_of_mass
	center_of_buoyancy_indicator.global_position = data.center_of_buoyancy_world
