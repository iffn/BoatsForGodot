extends RigidBody3D

class_name BoatController

@export var _hull : BoatHull
@export var _thrusters : Array[BoatThruster]

var hull : BoatHull:
	get:
		return _hull

var thrusters : Array[BoatThruster]:
	get:
		return _thrusters

@export var _current_update_state := update_states.INGAME_UPDATE

var boat_state : BoatState:
	get:
		return BoatState.new(global_position, global_rotation, linear_velocity, angular_velocity)
	set(new_state):
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
			update_states.IDLE:
				sleeping = true
				freeze = true
				if _hull:
					hull.set_physics_process(false)
				for thruster in _thrusters:
					thruster.set_physics_process(false)
				pass
		_current_update_state = value

func _ready() -> void:
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
