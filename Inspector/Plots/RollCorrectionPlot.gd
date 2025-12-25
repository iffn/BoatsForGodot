extends Node

@export var calculation_boat : BoatController
@export var roll_correction_plot : EasyChartPlot

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
	
	var function := Function.new(
		x_values, y_values, "Roll correction torque [Nm]",
		{ 
			color = Color("ff0000ff"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	roll_correction_plot.display_data([function])
	
	# Reset
	calculation_boat.position = original_position
	calculation_boat.rotation = original_rotation
