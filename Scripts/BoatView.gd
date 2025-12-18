@tool
extends Node


var _view_direction := view_directions.RIGHT_SIDE
@export var view_direction : view_directions:
	set(value):
		match value:
			view_directions.FRONT:
				boat.rotation_degrees = Vector3(0, -90, 0)
			view_directions.RIGHT_SIDE:
				boat.rotation_degrees = Vector3(0, 0, 0)
			view_directions.TOP_FRONT_RIGHT:
				boat.rotation_degrees = Vector3(0, 0, -90)
		_view_direction = value
	get:
		return _view_direction

@export var _boat : BoatController
var boat : BoatController:
	get:
		return _boat

enum view_directions
{
	RIGHT_SIDE,
	FRONT,
	TOP_FRONT_RIGHT
}
