extends Node

@export var boat_view : BoatView
var calculation_boat : BoatController:
	get:
		return boat_view.linked_boat

@export var chart: Chart

var function: Function

var cp: ChartProperties = ChartProperties.new()

func _ready() -> void:
	var x: Array[float] = [-180.0, 180.0]
	var y: Array[float] = [0.0, 0.0]
	
	cp = EaysChartHelper.get_default_chart_values()
	
	cp.title = "Roll correction relative to roll angle"
	cp.x_label = "Roll angle [°]"
	cp.y_label = "Torque [Nm]"
	cp.x_scale = 10
	cp.y_scale = 10
	cp.interactive = true 
	cp.show_legend = false
	
	function = Function.new(
		x, y, "Torque data",
		{ 
			color = Color("ff0000ff"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	chart.plot([function], cp)

func plot_graph():
	var original_position := calculation_boat.position
	var original_rotation := calculation_boat.rotation
	
	var buoyancy_goal := calculation_boat.mass * 9.81
	
	var data : BoatHull.BoatCalculationData
	
	function.__x.clear()
	function.__y.clear()
	
	for angle_deg in range(-180, 185, 5):
		calculation_boat.rotation_degrees = Vector3(0, 0, angle_deg)
		var water_line := calculation_boat.hull.find_waterline(buoyancy_goal)
		calculation_boat.position.y = water_line
		data = calculation_boat.hull.calculate_all()
		var y : float = -sign(angle_deg)*data.buoyancy_torque.z
		
		function.add_point(angle_deg, y)
	
	EaysChartHelper.set_min_max([function], chart)
	
	chart.queue_redraw()
	
	# Reset
	calculation_boat.position = original_position
	calculation_boat.rotation = original_rotation
