extends Node

class_name BoatView

@export var _linked_boat : BoatController
var linked_boat : BoatController:
	get:
		return _linked_boat

@export var _camera_followers : Array[Follower]

func _ready() -> void:
	for follower in _camera_followers:
		follower.setup(_linked_boat)
