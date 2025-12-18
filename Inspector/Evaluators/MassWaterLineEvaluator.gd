extends Node
@export var calculation_boat : BoatController

@export var _mass_or_waterline : OptionButton
@export var _mass_line : Control
@export var _waterline_line : Control
@export var _mass_input : LineEdit
@export var _waterline_input : LineEdit
@export var _output : Label

const waterline_from_mass := 0
const mass_from_waterline := 1

func _ready() -> void:
	mass_or_waterline_selected(_mass_or_waterline.selected)

func mass_or_waterline_selected(selected: int):
	_waterline_line.visible = selected == mass_from_waterline
	_mass_line.visible = selected == waterline_from_mass

func evaluate_waterline():
	match _mass_or_waterline.selected:
		waterline_from_mass:
			_output.text = "Waterline: n m"
		mass_from_waterline:
			var waterline = float(_waterline_input.text)
			_waterline_input.text = str(waterline)
			calculation_boat.position.y = -waterline
			var data := calculation_boat.hull.calculate_all()
			var mass = data.buoyancy_force.y / 9.81
			_output.text = "Boat mass: " + str(mass).pad_decimals(2) +  " kg"
