extends Node
@export var boat_syncronizer : BoatEditSyncronizer
var calculation_boat : BoatController:
	get:
		return boat_syncronizer.calculation_boat
@export var _evaluate_button : Button
@export var _mass_or_waterline : OptionButton
@export var _mass_line : Control
@export var _waterline_line : Control
@export var _mass_input : SpinBox
@export var _waterline_input : SpinBox
@export var _output : Label

const waterline_from_mass := 0
const mass_from_waterline := 1

func _ready() -> void:
	boat_syncronizer.boat_modified.connect(boat_modified)
	_mass_input.connect("value_changed", set_mass)
	_waterline_input.connect("value_changed", set_waterline)

func boat_modified():
	_mass_input.set_value_no_signal(calculation_boat.mass) 
	
	_evaluate_button.text = "Out of date. Click to update"
	
	_waterline_line.visible = _mass_or_waterline.selected == mass_from_waterline
	_mass_line.visible = _mass_or_waterline.selected == waterline_from_mass

func mass_or_waterline_selected(selected: int):
	_waterline_line.visible = selected == mass_from_waterline
	_mass_line.visible = selected == waterline_from_mass
	set_mass(calculation_boat.mass)
	set_waterline(calculation_boat.position.y)
	
func evaluate_waterline():
	var data : BoatHull.BoatCalculationData
	
	match _mass_or_waterline.selected:
		waterline_from_mass:
			var buoyancy_goal := calculation_boat.mass * 9.81
			var waterline := calculation_boat.hull.find_waterline(buoyancy_goal)
			_output.text = "Waterline from origin: " + str(waterline).pad_decimals(2) + " m"
			set_waterline(waterline)
		mass_from_waterline:
			var waterline := _waterline_input.value
			calculation_boat.position.y = waterline
			data = calculation_boat.hull.calculate_all()
			var mass = data.buoyancy_force.y / 9.81
			_output.text = "Boat mass: " + str(mass).pad_decimals(1) +  " kg"
			set_mass(mass)
	
	_evaluate_button.text = "Up to date"

func set_mass(value : float):
	calculation_boat.mass = value
	_mass_input.set_value_no_signal(value)
	boat_syncronizer.boat_modified.emit()

func set_waterline(value : float):
	_waterline_input.set_value_no_signal(value)
	calculation_boat.position.y = value
	boat_syncronizer.boat_modified.emit()
