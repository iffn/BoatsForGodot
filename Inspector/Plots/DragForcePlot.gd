extends Node

@export var calculation_boat : BoatController
@export var chart: Chart

var friction_drag_funciton : Function
var pressure_drag_funciton : Function
var total_drag_funciton : Function

var cp: ChartProperties = ChartProperties.new()

func _ready() -> void:
	var x: Array[float] = [-180.0, 180.0]
	var y: Array[float] = [0.0, 0.0]
	
	cp = EaysChartHelper.get_default_chart_values()
	
	cp.title = "Drag force at speed"
	cp.x_label = "Speed [m/s]"
	cp.y_label = "Force [N]"
	cp.x_scale = 10
	cp.y_scale = 10
	cp.interactive = true 
	cp.show_legend = false
	
	friction_drag_funciton = Function.new(
		x, y, "Friction drag [N]",
		{ 
			color = Color("636363ff"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	pressure_drag_funciton = Function.new(
		x, y, "Pressure drag [N]",
		{ 
			color = Color("ff0000ff"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	total_drag_funciton = Function.new(
		x, y, "Total drag [N]",
		{ 
			color = Color("00ccffff"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	chart.plot([friction_drag_funciton, pressure_drag_funciton, total_drag_funciton], cp)

func plot_graph():
	var original_position := calculation_boat.position
	var original_rotation := calculation_boat.rotation
	var original_linear_velocity := calculation_boat.linear_velocity
	
	var buoyancy_goal := calculation_boat.mass * 9.81
	
	var data : BoatHull.BoatCalculationData
	
	friction_drag_funciton.__x.clear()
	friction_drag_funciton.__y.clear()
	pressure_drag_funciton.__x.clear()
	pressure_drag_funciton.__y.clear()
	total_drag_funciton.__x.clear()
	total_drag_funciton.__y.clear()
	
	for speed in range(0, 51, 1):
		calculation_boat.linear_velocity = Vector3(0, 0, -speed)
		var water_line := calculation_boat.hull.find_waterline(buoyancy_goal)
		calculation_boat.position.y = water_line
		data = calculation_boat.hull.calculate_all()
		
		friction_drag_funciton.add_point(speed, data.friction_drag_force.z)
		pressure_drag_funciton.add_point(speed, data.pressure_drag_force.z)
		total_drag_funciton.add_point(speed, (data.friction_drag_force + data.pressure_drag_force).z)
	
	EaysChartHelper.set_min_max([friction_drag_funciton, pressure_drag_funciton, total_drag_funciton], chart)
	
	chart.queue_redraw()
	
	# Reset
	calculation_boat.position = original_position
	calculation_boat.rotation = original_rotation
	calculation_boat.linear_velocity = original_linear_velocity
