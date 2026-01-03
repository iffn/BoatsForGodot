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
				pass
		_current_update_state = value

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

func setup():
	_thrusters = []
	
	var all_descendants := boat_model.find_children("*", "", true)
	for child in all_descendants:
		if child.has_meta("extras"):
			var extras := child.get_meta("extras") as Dictionary
			if extras.has("ElementType"):
				if extras.get("ElementType") == "DisplacementMesh":
					mass = (float)(extras.get("Mass"))
					_hull = BoatHull.new()
					add_child(_hull)
					var hull_mesh := child as MeshInstance3D
					if hull_mesh == null:
						print("Hull mesh not found")
					else:
						print("Hull mesh found")
					
					_hull.drag_multiplier = drag_multiplier
					_hull.buoyancy_multiplier = buoyancy_multiplier
					_hull.setup(hull_mesh, self, _water_level)
					print("Hull set up")
				if extras.get("ElementType") == "Thruster":
					var MaxHorizontalRotationDeg := (float)(extras.get("MaxHorizontalRotationDeg"))
					var MaxVerticalRotationDeg := (float)(extras.get("MaxVerticalRotationDeg"))
					var Thrust := (float)(extras.get("Thrust"))
					child.set_script(BoatThruster)
					var thruster := child as BoatThruster
					thruster.engine_thrust = Thrust
					thruster.engine_pitch_deg = MaxVerticalRotationDeg
					thruster.engine_rotation_deg = MaxHorizontalRotationDeg
					thruster.input_forward = input_forward
					thruster.input_backward = input_backward
					thruster.input_right = input_right
					thruster.input_left = input_left
					thruster.linked_rigidbody = self
					_thrusters.append(thruster)
	
	intertia_calculator.calculate_and_set_inertia()
	
	current_update_state = _current_update_state

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
