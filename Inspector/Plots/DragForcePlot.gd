extends Node

@export var calculation_boat : BoatController
@export var drag_force_plot : EasyChartPlot

func plot_graph():
	var original_position := calculation_boat.position
	var original_rotation := calculation_boat.rotation
	var original_linear_velocity := calculation_boat.linear_velocity
	
	var buoyancy_goal := calculation_boat.mass * 9.81
	
	var data : BoatHull.BoatCalculationData
	
	var x_values : Array[float] = []
	var y_values : Array[float] = []
	
	for speed in range(-0, 51, 1):
		x_values.append(speed)
		calculation_boat.linear_velocity = Vector3(0, 0, -speed)
		var water_line := calculation_boat.hull.find_waterline(buoyancy_goal)
		calculation_boat.position.y = water_line
		data = calculation_boat.hull.calculate_all()
		y_values.append((data.friction_drag_force + data.pressure_drag_force).z)
	
	drag_force_plot.display_data(x_values, y_values, "Roll correction")
	
	# Reset
	calculation_boat.position = original_position
	calculation_boat.rotation = original_rotation
	calculation_boat.linear_velocity = original_linear_velocity
