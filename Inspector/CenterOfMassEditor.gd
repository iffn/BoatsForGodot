extends Node

@export var boat_syncronizer : BoatEditSyncronizer
var calculation_boat : BoatController:
	get:
		return boat_syncronizer.calculation_boat

@export var input_x : SpinBox
@export var input_y : SpinBox
@export var input_z : SpinBox

func _ready() -> void:
	input_x.connect("value_changed", set_com_x)
	input_y.connect("value_changed", set_com_y)
	input_z.connect("value_changed", set_com_z)
	boat_syncronizer.boat_modified.connect(get_center_of_mass)

func get_center_of_mass():
	input_x.value = calculation_boat.center_of_mass.x
	input_y.value = calculation_boat.center_of_mass.y
	input_z.value = calculation_boat.center_of_mass.z

func set_com_x(x : float):
	calculation_boat.center_of_mass.x = x
	boat_syncronizer.boat_modified.emit()

func set_com_y(y : float):
	calculation_boat.center_of_mass.y = y
	boat_syncronizer.boat_modified.emit()

func set_com_z(z : float):
	calculation_boat.center_of_mass.z = z
	boat_syncronizer.boat_modified.emit()
