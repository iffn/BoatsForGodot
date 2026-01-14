extends Node

class_name BoatEditSyncronizer

@export var calculation_boat: BoatController

signal _boat_modified
signal _boat_modified_calculated(data: BoatHull.BoatCalculationData)

func _ready() -> void:
	_boat_modified.emit.call_deferred() # Emits signal at the end of the frame
	#var data := calculation_boat.hull.calculate_all()
	#_boat_modified_calculated.emit.call_deferred(data) # Emits signal at the end of the frame

func connect_boat_modified(callable: Callable):
	_boat_modified.connect(callable)

func connect_boat_modified_calculated(callable: Callable):
	_boat_modified_calculated.connect(callable)

func emit_signals():
	_boat_modified.emit()
	var data := calculation_boat.hull.calculate_all()
	_boat_modified_calculated.emit(data)
