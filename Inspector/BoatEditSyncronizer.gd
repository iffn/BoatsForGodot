extends Node

class_name BoatEditSyncronizer

@export var calculation_boat: BoatController

signal boat_modified

func _ready() -> void:
	boat_modified.emit.call_deferred() # Emits signal at the end of the frame
