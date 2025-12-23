extends Node

@export var calculation_boat : BoatController
@export var graph : Line2D
@export var x_max := 250.0
@export var y_max := 85.0

func plot_graph():
	var original_position := calculation_boat.position
	var original_rotation := calculation_boat.rotation
	
	var buoyancy_goal := calculation_boat.mass * 9.81
	
	var data : BoatHull.BoatCalculationData
	
	var x_values : Array[float] = []
	var y_values : Array[float] = []
	
	for angle_deg in range(-180, 185, 5):
		x_values.append(angle_deg)
		calculation_boat.rotation_degrees = Vector3(0, 0, angle_deg)
		var water_line := calculation_boat.hull.find_waterline(buoyancy_goal)
		calculation_boat.position.y = water_line
		data = calculation_boat.hull.calculate_all()
		y_values.append(-sign(angle_deg)*data.buoyancy_torque.z)
		#y_values.append(angle_deg)
	
	var y_output_max : float = y_values.max() if y_values.max() > -y_values.min() else -y_values.min()
	
	var x_scale : float = x_max / (x_values.max() - x_values.min())
	var y_scale : float = y_max / (y_output_max)
	var x_offset : float = -x_values.min() * x_scale
	
	graph.clear_points()
	for i in range(x_values.size()):
		graph.add_point(Vector2(x_values[i] * x_scale + x_offset, y_values[i] * y_scale))
	
	calculation_boat.position = original_position
	calculation_boat.rotation = original_rotation
