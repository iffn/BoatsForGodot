extends Node

@export var calculation_boat : BoatController
@export var force_chart: Chart
@export var position_chart: Chart
@export var torque_chart: Chart

var friction_drag_funciton : Function
var pressure_drag_funciton : Function
var total_drag_funciton : Function
var lift_force_function : Function
var level_position_function : Function
var pitch_torque_function : Function

var cp_forces: ChartProperties = ChartProperties.new()
var cp_position: ChartProperties = ChartProperties.new()
var cp_torque: ChartProperties = ChartProperties.new()

func _ready() -> void:
	var x: Array[float] = [0.0, 50.0]
	var y: Array[float] = [0.0, 0.0]
	
	cp_forces = EaysChartHelper.get_default_chart_values()
	cp_forces.title = "Forces at speed"
	cp_forces.x_label = "Speed [m/s]"
	cp_forces.y_label = "Force [N]"
	cp_forces.x_scale = 10
	cp_forces.y_scale = 10
	cp_forces.interactive = true 
	cp_forces.show_legend = true
	
	cp_position = EaysChartHelper.get_default_chart_values()
	cp_position.title = "Position at speed"
	cp_position.x_label = "Speed [m/s]"
	cp_position.y_label = "Position [m]"
	cp_position.x_scale = 10
	cp_position.y_scale = 10
	cp_position.interactive = true 
	cp_position.show_legend = false
	
	cp_torque = EaysChartHelper.get_default_chart_values()
	cp_torque.title = "Torque at speed"
	cp_torque.x_label = "Speed [m/s]"
	cp_torque.y_label = "Torque [Nm]"
	cp_torque.x_scale = 10
	cp_torque.y_scale = 10
	cp_torque.interactive = true 
	cp_torque.show_legend = false
	
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
	
	lift_force_function = Function.new(
		x, y, "Lift force [N]",
		{ 
			color = Color("9d00ffff"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	level_position_function = Function.new(
		x, y, "Level position [m]",
		{ 
			color = Color("00ff00ff"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	pitch_torque_function = Function.new(
		x, y, "Pitch torque [Nm]",
		{ 
			color = Color("ff0000ff"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	force_chart.plot([friction_drag_funciton, pressure_drag_funciton, total_drag_funciton, lift_force_function], cp_forces)
	position_chart.plot([level_position_function], cp_position)
	torque_chart.plot([pitch_torque_function], cp_torque)

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
	lift_force_function.__x.clear()
	lift_force_function.__y.clear()
	level_position_function.__x.clear()
	level_position_function.__y.clear()
	pitch_torque_function.__x.clear()
	pitch_torque_function.__y.clear()
	
	for speed in range(0, 51, 1):
		calculation_boat.linear_velocity = Vector3(0, 0, -speed)
		var water_line := calculation_boat.hull.find_waterline(buoyancy_goal)
		calculation_boat.position.y = water_line
		data = calculation_boat.hull.calculate_all()
		
		friction_drag_funciton.add_point(speed, data.friction_drag_force.z)
		pressure_drag_funciton.add_point(speed, data.pressure_drag_force.z)
		total_drag_funciton.add_point(speed, (data.friction_drag_force + data.pressure_drag_force).z)
		lift_force_function.add_point(speed, (data.friction_drag_force + data.pressure_drag_force).y)
		level_position_function.add_point(speed, water_line)
		pitch_torque_function.add_point(speed, data.all_torques.x)
	
	EaysChartHelper.set_min_max([friction_drag_funciton, pressure_drag_funciton, total_drag_funciton, lift_force_function], force_chart)
	EaysChartHelper.set_min_max([level_position_function], position_chart)
	EaysChartHelper.set_min_max([pitch_torque_function], torque_chart)
	
	force_chart.queue_redraw()
	position_chart.queue_redraw()
	torque_chart.queue_redraw()
	
	# Reset
	calculation_boat.position = original_position
	calculation_boat.rotation = original_rotation
	calculation_boat.linear_velocity = original_linear_velocity
