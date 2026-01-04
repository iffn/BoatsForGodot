extends Node

class_name BoatEditSyncronizer

@export var boat_view : BoatView
var calculation_boat : BoatController:
	get:
		return boat_view.linked_boat

signal boat_modified

func _ready() -> void:
	boat_modified.emit.call_deferred() # Emits signal at the end of the frame
