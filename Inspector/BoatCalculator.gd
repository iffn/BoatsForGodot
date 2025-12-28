@tool
extends Node

class_name BoatCalculator

@export var calculation_boat : BoatController

@export var display_from_inputs : CheckButton

@export var height_position_input : LineEdit
@export var pitch_input : LineEdit
@export var yaw_input : LineEdit
@export var roll_input : LineEdit
@export var linear_velocity_x_input : LineEdit
@export var linear_velocity_y_input : LineEdit
@export var linear_velocity_z_input : LineEdit
@export var angular_velocity_x_input : LineEdit
@export var angular_velocity_y_input : LineEdit
@export var angular_velocity_z_input : LineEdit

@export var _output_holder_name: Control 
@export var _output_holder_x: Control
@export var _output_holder_y: Control
@export var _output_holder_z: Control

@export var center_evaluator: CenterEvaluator
@export var visualize_underwater_mesh: VisualizeUnderwaterMesh

var initial_state : BoatController.BoatState
var _update_counter := 0
var _current_update_state := update_states.FROZEN

enum update_states {
	FROZEN,
	LIMITED_STEPS,
	SIMULATING
}

var current_update_state : update_states:
	get:
		return _current_update_state
	set(value):
		match value:
			update_states.FROZEN:
				calculation_boat.state = BoatController.states.IDLE
			update_states.LIMITED_STEPS:
				calculation_boat.state = BoatController.states.INGAME_UPDATE
				_update_counter = 0
			update_states.SIMULATING:
				calculation_boat.state = BoatController.states.INGAME_UPDATE
		_current_update_state = value

func _ready() -> void:
	initial_state = calculation_boat.boat_state
	
	calculation_boat.state = BoatController.states.IDLE
	
	_set_input_state(initial_state)
	
	if !Engine.is_editor_hint():
		height_position_input.text_submitted.connect(update_from_inputs)
		pitch_input.text_submitted.connect(update_from_inputs)
		yaw_input.text_submitted.connect(update_from_inputs)
		roll_input.text_submitted.connect(update_from_inputs)
		linear_velocity_x_input.text_submitted.connect(update_from_inputs)
		linear_velocity_y_input.text_submitted.connect(update_from_inputs)
		linear_velocity_z_input.text_submitted.connect(update_from_inputs)
		angular_velocity_x_input.text_submitted.connect(update_from_inputs)
		angular_velocity_y_input.text_submitted.connect(update_from_inputs)
		angular_velocity_z_input.text_submitted.connect(update_from_inputs)

func _physics_process(delta: float) -> void:
	if current_update_state == update_states.LIMITED_STEPS:
		if _update_counter >= 1:
			current_update_state = update_states.FROZEN
		else:
			_update_counter += 1
			center_evaluator.update_centers()
			visualize_underwater_mesh.update_underwater_mesh()
			_evaluate_geometry()
			
	elif current_update_state == update_states.SIMULATING:
		center_evaluator.update_centers()
		visualize_underwater_mesh.update_underwater_mesh()
		_evaluate_geometry()

func play_pause():
	match _current_update_state:
		update_states.FROZEN:
			current_update_state = update_states.SIMULATING
		update_states.LIMITED_STEPS:
			current_update_state = update_states.SIMULATING
		update_states.SIMULATING:
			current_update_state = update_states.FROZEN

func calculate_next_step():
	current_update_state = update_states.LIMITED_STEPS

func get_state_from_rigidbody():
	var state := calculation_boat.boat_state
	
	_set_input_state(state)

func reset_state():
	_set_input_state(initial_state)
	if display_from_inputs.button_pressed:
		update_state()

func update_state():
	_set_boat_state_from_inputs()
	_evaluate_geometry()
	center_evaluator.update_centers()
	visualize_underwater_mesh.update_underwater_mesh()

func find_water_height():
	var height := calculation_boat.hull.find_waterline(9.81 * calculation_boat.mass)
	var state := calculation_boat.boat_state
	state.position.y = height
	calculation_boat.boat_state = state
	_set_input_state(state)
	_evaluate_geometry()
	center_evaluator.update_centers()
	visualize_underwater_mesh.update_underwater_mesh()

func update_from_inputs(new_text: String):
	if !display_from_inputs.button_pressed:
		return
	
	update_state()
	

func _set_input_state(new_state : BoatController.BoatState):
	height_position_input.text = str(new_state.position.y).pad_decimals(2)
	
	pitch_input.text = str(rad_to_deg(new_state.rotation.x)).pad_decimals(2)
	yaw_input.text = str(rad_to_deg(new_state.rotation.y)).pad_decimals(2)
	roll_input.text = str(rad_to_deg(new_state.rotation.z)).pad_decimals(2)
	
	linear_velocity_x_input.text = str(new_state.linear_velocity.x).pad_decimals(2)
	linear_velocity_y_input.text = str(new_state.linear_velocity.y).pad_decimals(2)
	linear_velocity_z_input.text = str(new_state.linear_velocity.z).pad_decimals(2)
	
	angular_velocity_x_input.text = str(new_state.angular_velocity.x).pad_decimals(2)
	angular_velocity_y_input.text = str(new_state.angular_velocity.y).pad_decimals(2)
	angular_velocity_z_input.text = str(new_state.angular_velocity.z).pad_decimals(2)

func _set_boat_state_from_inputs():
	var new_state := BoatController.BoatState.new(
			Vector3(0, float(height_position_input.text), 0),
			Vector3(deg_to_rad(float(pitch_input.text)), deg_to_rad(float(yaw_input.text)), deg_to_rad(float(roll_input.text))),
			Vector3(float(linear_velocity_x_input.text), float(linear_velocity_y_input.text), float(linear_velocity_z_input.text)),
			Vector3(float(angular_velocity_x_input.text), float(angular_velocity_y_input.text), float(angular_velocity_z_input.text))
		)
	
	calculation_boat.boat_state = new_state

func _evaluate_geometry():
	var names := _output_holder_name.find_children("*", "Label")
	var output_x := _output_holder_x.find_children("*", "Label")
	var output_y := _output_holder_y.find_children("*", "Label")
	var output_z := _output_holder_z.find_children("*", "Label")
	
	var i = 0
	
	var data : BoatHull.BoatCalculationData = calculation_boat.hull.calculate_all()
	
	names[i].text = "Triangles below water"
	output_z[i].text = str(data.triangles_below_water.size())
	i+=1
	
	names[i].text = "Waterline points"
	output_z[i].text = str(data.waterline_points.size())
	i+=1
	
	names[i].text = "Water plane size"
	output_x[i].text = str(data.water_plane_size_XZ.x).pad_decimals(2)
	output_y[i].text = ""
	output_z[i].text = str(data.water_plane_size_XZ.y).pad_decimals(2)
	i+=1
	
	names[i].text = "Center of buoyancy"
	output_x[i].text = str(data.center_of_buoyancy_world.x).pad_decimals(2)
	output_y[i].text = str(data.center_of_buoyancy_world.y).pad_decimals(2)
	output_z[i].text = str(data.center_of_buoyancy_world.z).pad_decimals(2)
	i+=1
	
	names[i].text = "Displaced volume"
	output_z[i].text = str(data.displaced_volume).pad_decimals(2)
	i+=1
	
	names[i].text = "Buoyancy force"
	output_x[i].text = str(data.buoyancy_force.x).pad_decimals(2)
	output_y[i].text = str(data.buoyancy_force.y).pad_decimals(2)
	output_z[i].text = str(data.buoyancy_force.z).pad_decimals(2)
	i+=1
	
	names[i].text = "Friction drag force"
	output_x[i].text = str(data.friction_drag_force.x).pad_decimals(2)
	output_y[i].text = str(data.friction_drag_force.y).pad_decimals(2)
	output_z[i].text = str(data.friction_drag_force.z).pad_decimals(2)
	i+=1
	
	names[i].text = "Pressure drag force"
	output_x[i].text = str(data.pressure_drag_force.x).pad_decimals(2)
	output_y[i].text = str(data.pressure_drag_force.y).pad_decimals(2)
	output_z[i].text = str(data.pressure_drag_force.z).pad_decimals(2)
	i+=1
	
	names[i].text = "Total drag force"
	output_x[i].text = str(data.all_forces.x).pad_decimals(2)
	output_y[i].text = str(data.all_forces.y).pad_decimals(2)
	output_z[i].text = str(data.all_forces.z).pad_decimals(2)
	i+=1
	
	names[i].text = "Buoyancy torque"
	output_x[i].text = str(data.buoyancy_torque.x).pad_decimals(2)
	output_y[i].text = str(data.buoyancy_torque.y).pad_decimals(2)
	output_z[i].text = str(data.buoyancy_torque.z).pad_decimals(2)
	i+=1
	
	names[i].text = "Friction drag torque"
	output_x[i].text = str(data.friction_drag_torque.x).pad_decimals(2)
	output_y[i].text = str(data.friction_drag_torque.y).pad_decimals(2)
	output_z[i].text = str(data.friction_drag_torque.z).pad_decimals(2)
	i+=1
	
	names[i].text = "Pressure drag torque"
	output_x[i].text = str(data.pressure_drag_torque.x).pad_decimals(2)
	output_y[i].text = str(data.pressure_drag_torque.y).pad_decimals(2)
	output_z[i].text = str(data.pressure_drag_torque.z).pad_decimals(2)
	i+=1
	
	names[i].text = "Total drag torque"
	output_x[i].text = str(data.all_torques.x).pad_decimals(2)
	output_y[i].text = str(data.all_torques.y).pad_decimals(2)
	output_z[i].text = str(data.all_torques.z).pad_decimals(2)
	i+=1

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_POST_SAVE:
			update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_EDITOR and prop.usage & PROPERTY_USAGE_CHECKABLE == 0:
			if prop.name in ["script", "Built-in Script"]: 
				continue
			
			if get(prop.name) == null:
				warnings.append("Variable '%s' is unassigned!" % prop.name.capitalize())
				
	return warnings
