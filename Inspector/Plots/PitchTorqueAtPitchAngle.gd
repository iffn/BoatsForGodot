extends Node

@export var boat_view : BoatView
var calculation_boat : BoatController:
	get:
		return boat_view.linked_boat

@export var chart: Chart

@export var speeds: Array[float]
var functions: Array[Function]

var cp: ChartProperties = ChartProperties.new()

func _ready() -> void:
	var x: Array[float] = [-180.0, 180.0]
	var y: Array[float] = [0.0, 0.0]
	
	cp = EaysChartHelper.get_default_chart_values()
	
	cp.title = "Pitch torque at speed"
	cp.x_label = "Pitch angle [°]"
	cp.y_label = "Torque [Nm]"
	cp.x_scale = 10
	cp.y_scale = 10
	cp.interactive = true 
	cp.show_legend = true
	
	for i in range(speeds.size()):
		var hue := 1.0 / speeds.size() * i
		
		var function = Function.new(
			x, y, "Torque data at " + str(speeds[i]) + "m/s",
			{
				color = Color.from_hsv(hue, 1.0, 1.0, 1.0),
				marker = Function.Marker.CIRCLE,
				type = Function.Type.LINE,
				interpolation = Function.Interpolation.LINEAR
			}
		)
		functions.append(function)
	
	chart.plot(functions, cp)

func plot_graph():
	var original_position := calculation_boat.position
	var original_rotation := calculation_boat.rotation
	var original_linear_velocity := calculation_boat.linear_velocity
	
	var buoyancy_goal := calculation_boat.mass * 9.81
	
	var data : BoatHull.BoatCalculationData
	
	for i in range(functions.size()):
		var function = functions[i]
		
		function.__x.clear()
		function.__y.clear()
		
		for angle_deg in range(0, 20, 1):
			calculation_boat.linear_velocity = Vector3(0, 0, speeds[i])
			calculation_boat.rotation_degrees = Vector3(angle_deg, 0, 0) # Positive = pitch up
			var water_line := calculation_boat.hull.find_waterline(buoyancy_goal)
			calculation_boat.position.y = water_line
			data = calculation_boat.hull.calculate_all()
			var y : float = data.all_torques.x
			
			function.add_point(angle_deg, y)
	
	EaysChartHelper.set_min_max(functions, chart)
	
	chart.queue_redraw()
	
	# Reset
	calculation_boat.position = original_position
	calculation_boat.rotation = original_rotation
	calculation_boat.linear_velocity = original_linear_velocity
