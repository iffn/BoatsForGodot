extends Node

@export var calculation_boat : BoatController

@export var input_x : SpinBox
@export var input_y : SpinBox
@export var input_z : SpinBox

func _ready() -> void:
	input_x.connect("value_changed", set_com_x)
	input_y.connect("value_changed", set_com_y)
	input_z.connect("value_changed", set_com_z)

func get_center_of_mass():
	input_x.value = calculation_boat.center_of_mass.x
	input_y.text = calculation_boat.center_of_mass.y
	input_z.text = calculation_boat.center_of_mass.z

func set_com_x(x : float):
	calculation_boat.center_of_mass.x = x
	print("Set to ", x)

func set_com_y(y : float):
	calculation_boat.center_of_mass.y = y

func set_com_z(z : float):
	calculation_boat.center_of_mass.z = z
