extends RigidBody3D

class_name BoatController

@export var _hull : BoatHull
@export var _thruster : BoatThruster

var hull : BoatHull:
	get:
		return _hull

@export var _state := states.INGAME_UPDATE

var state : states:
	get:
		return _state
	set(value):
		match state:
			states.INGAME_UPDATE:
				sleeping = false
				freeze = false
				if _hull:
					hull.set_physics_process(true)
				if _thruster:
					_thruster.set_physics_process(true)
			states.IDLE:
				sleeping = true
				freeze = true
				if _hull:
					hull.set_physics_process(false)
				if _thruster:
					_thruster.set_physics_process(false)
				pass
		_state = value

func _ready() -> void:
	state = _state

enum states {
	INGAME_UPDATE,
	IDLE
}
