extends RigidBody3D

class_name BoatController

@export var _water_level: WaterLevelProvider
@export var drag_multiplier : float  = 1.0
@export var buoyancy_multiplier : float  = 1.0
@export var intertia_calculator : InertiaCalculator
@export var _current_update_state := update_states.INGAME_UPDATE
@export var input_forward : InputResource
@export var input_backward : InputResource
@export var input_right : InputResource
@export var input_left : InputResource
@export var trim_up : InputResource
@export var trim_down : InputResource
@export var boat_model : Node3D

var hull : BoatHull:
	get:
		return _hull

var thrusters : Array[BoatThruster]:
	get:
		return _thrusters

var _hull : BoatHull
var _thrusters : Array[BoatThruster]

var _boat_sate : BoatState
var boat_state : BoatState:
	get:
		return BoatState.new(global_position, global_rotation, linear_velocity, angular_velocity)
	set(new_state):
		_boat_sate = new_state
		global_position = new_state.position
		global_rotation = new_state.rotation
		linear_velocity = new_state.linear_velocity
		angular_velocity = new_state.angular_velocity

var current_update_state : update_states:
	get:
		return _current_update_state
	set(value):
		match value:
			update_states.INGAME_UPDATE:
				sleeping = false
				freeze = false
				if _hull:
					hull.set_physics_process(true)
				for thruster in _thrusters:
					thruster.set_physics_process(true)
					pass
				_boat_sate.position = global_position
				_boat_sate.rotation = global_rotation
				boat_state = _boat_sate # Recovers the velocity from before freezing
			update_states.IDLE:
				_boat_sate = boat_state # Saves the velocity before freezing
				sleeping = true
				freeze = true
				if _hull:
					hull.set_physics_process(false)
				for thruster in _thrusters:
					thruster.set_physics_process(false)
		_current_update_state = value

var last_report : Array[String] = []

func _ready() -> void:
	_boat_sate = boat_state
	setup()

func replace_boat_model(new_boat_model : Node3D):
	boat_model.queue_free()
	
	boat_model = new_boat_model
	
	boat_model.position = Vector3.ZERO
	boat_model.rotation = Vector3.ZERO
	boat_model.scale = Vector3.ONE
	
	setup()

func prepare_boat_model_for_export():
	var extras : Dictionary
	
	extras = center_of_mass_object.get_meta("extras")
	extras["Mass"] = mass
	center_of_mass_object.set_meta("extras", extras)
	
	for thruster in _thrusters:
		extras = thruster.get_meta("extras")
		extras["Thrust"] = thruster.engine_thrust
		extras["MaxHorizontalRotationDeg"] = thruster.engine_rotation_deg
		extras["MaxVerticalRotationDeg"] = thruster.trim_deg
		thruster.set_meta("extras", extras)

var center_of_mass_object : Node3D

func setup():
	_thrusters = []
	
	if hull != null:
		print("Destroying hull")
		hull.queue_free()
	
	var valid_thrusters_found := 0
	var hulls_found := 0
	var center_of_masses_found := 0
	var masses_found := 0
	
	var all_descendants := boat_model.find_children("*", "", true)
	for child in all_descendants:
		if child.has_meta("extras"):
			var extras := child.get_meta("extras") as Dictionary
			if extras.has("ElementType"):
				if extras.get("ElementType") == "CenterOfMass":
					if child is Node3D:
						center_of_mass_object = child
						center_of_masses_found += 1
						center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
						center_of_mass = (child as Node3D).position
						if extras.has("ElementType"):
							mass = (float)(extras.get("Mass"))
							masses_found += 1
				if extras.get("ElementType") == "DisplacementMesh":
					_hull = BoatHull.new()
					var hull_mesh := child as MeshInstance3D
					if hull_mesh != null:
						hulls_found += 1
					if hulls_found > 1:
						continue # Currently only 1 hull supported
					add_child(_hull)
					_hull.drag_multiplier = drag_multiplier
					_hull.buoyancy_multiplier = buoyancy_multiplier
					_hull.setup(hull_mesh, self, _water_level)
				if extras.get("ElementType") == "Thruster":
					child.set_script(BoatThruster)
					var thruster := child as BoatThruster
					if extras.has("MaxHorizontalRotationDeg"):
						thruster.engine_rotation_deg = (float)(extras.get("MaxHorizontalRotationDeg"))
					if extras.has("MaxVerticalRotationDeg"):
						thruster.trim_deg = (float)(extras.get("MaxVerticalRotationDeg"))
					if extras.has("Thrust"):
						thruster.engine_thrust = (float)(extras.get("Thrust"))
						valid_thrusters_found += 1
					thruster.input_forward = input_forward
					thruster.input_backward = input_backward
					thruster.input_right = input_right
					thruster.input_left = input_left
					thruster.trim_up = trim_up
					thruster.trim_down = trim_down
					thruster.linked_rigidbody = self
					thruster.set_process(true)
					_thrusters.append(thruster)
	
	intertia_calculator.calculate_and_set_inertia()
	
	current_update_state = _current_update_state
	
	last_report = []
	last_report.append("Hulls found: " + str(hulls_found) + " (Note: Currently only 1 supported)")
	last_report.append("Center of masses found: " + str(center_of_masses_found))
	last_report.append("Masses found: " + str(masses_found))
	last_report.append("Valid thrusters found: " + str(valid_thrusters_found))

enum update_states {
	INGAME_UPDATE,
	IDLE
}

class BoatState:
	var position : Vector3
	var rotation : Vector3
	var linear_velocity : Vector3
	var angular_velocity : Vector3
	
	func _init(the_position : Vector3, the_rotation : Vector3, the_linear_velocity : Vector3, the_angular_velocity : Vector3):
		position = the_position
		rotation = the_rotation
		linear_velocity = the_linear_velocity
		angular_velocity = the_angular_velocity
