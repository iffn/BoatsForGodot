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
	set_mass(calculation_boat.mass)
	set_waterline(calculation_boat.position.y)
	
func evaluate_waterline():
	var data : BoatHull.BoatCalculationData
	
	match _mass_or_waterline.selected:
		waterline_from_mass:
			var mass := float(_mass_input.text)
			set_mass(mass)
			var buoyancy_goal := mass * 9.81
			var waterline := calculation_boat.hull.find_waterline(buoyancy_goal)
			_output.text = "Waterline from origin: " + str(waterline).pad_decimals(2) + " m"
			set_waterline(waterline)
		mass_from_waterline:
			var waterline := float(_waterline_input.text)
			_waterline_input.text = str(waterline).pad_decimals(2)
			calculation_boat.position.y = waterline
			data = calculation_boat.hull.calculate_all()
			var mass = data.buoyancy_force.y / 9.81
			_output.text = "Boat mass: " + str(mass).pad_decimals(1) +  " kg"
			set_mass(mass)

func set_mass(value : float):
	calculation_boat.mass = value
	_mass_input.text = str(value).pad_decimals(1)

func set_waterline(value : float):
	_waterline_input.text = str(value).pad_decimals(2)
	calculation_boat.position.y = value
