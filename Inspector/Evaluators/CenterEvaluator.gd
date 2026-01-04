extends Node

class_name CenterEvaluator

@export var boat_syncronizer : BoatEditSyncronizer
var calculation_boat : BoatController:
	get:
		return boat_syncronizer.calculation_boat

@export var center_of_mass_indicator : Node3D
@export var center_of_buoyancy_indicator : Node3D

func _ready() -> void:
	boat_syncronizer.boat_modified.connect(update_centers)

func update_centers():
	var data := calculation_boat.hull.calculate_all()
	
	center_of_mass_indicator.global_position = calculation_boat.global_transform * calculation_boat.center_of_mass
	center_of_buoyancy_indicator.global_position = data.center_of_buoyancy_world
