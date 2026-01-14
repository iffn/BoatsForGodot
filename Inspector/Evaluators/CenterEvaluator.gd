extends Node

class_name CenterEvaluator

@export var boat_syncronizer : BoatEditSyncronizer
var calculation_boat : BoatController:
	get:
		return boat_syncronizer.calculation_boat

@export var center_of_mass_indicator : Node3D
@export var center_of_buoyancy_indicator : Node3D

var line_of_action_start : Vector3
var line_of_action_end : Vector3

func _ready() -> void:
	boat_syncronizer.connect_boat_modified_calculated(update_centers)

func _process(delta: float) -> void:
	var line_config := DebugDraw3D.new_scoped_config().set_no_depth_test(true).set_thickness(0.05)
	DebugDraw3D.draw_line(line_of_action_start, line_of_action_end, Color.DODGER_BLUE)

func update_centers(data: BoatHull.BoatCalculationData):
	var center_of_mass_world := calculation_boat.global_transform * calculation_boat.center_of_mass
	
	center_of_mass_indicator.global_position = center_of_mass_world
	#center_of_buoyancy_indicator.global_position = data.center_of_buoyancy_world
	
	var total_force := data.all_forces
	var total_torque := data.all_torques
	
	if total_force.length() > 0.0001:
		var f_length_sq = total_force.length_squared()
		var r_cp = total_force.cross(total_torque) / f_length_sq
		var center_of_pressure_world = center_of_mass_world + r_cp
		
		center_of_buoyancy_indicator.visible = true
		center_of_buoyancy_indicator.global_position = center_of_pressure_world
		
		var direction = total_force.normalized()
		var neutral_buoyancy_force = calculation_boat.mass * 9.81
		
		var force_factor = total_force.length() / neutral_buoyancy_force
		line_of_action_start = center_of_pressure_world
		line_of_action_end = center_of_pressure_world + direction * force_factor * 1.0
	else:
		center_of_buoyancy_indicator.visible = false
		line_of_action_start = Vector3.ZERO
		line_of_action_end = Vector3.ZERO
	
