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
	var data : BoatHull.BoatCalculationData
	
	match _mass_or_waterline.selected:
		waterline_from_mass:
			var mass := float(_mass_input.text)
			_mass_input.text = str(mass)
			var buoyancy_goal := mass * 9.81
			var waterline := find_waterline(buoyancy_goal)
			_output.text = "Waterline from origin: " + str(waterline).pad_decimals(2) + " m"
		mass_from_waterline:
			var waterline := float(_waterline_input.text)
			_waterline_input.text = str(waterline)
			calculation_boat.position.y = -waterline
			data = calculation_boat.hull.calculate_all()
			var mass = data.buoyancy_force.y / 9.81
			_output.text = "Boat mass: " + str(mass).pad_decimals(1) +  " kg"

func find_waterline(buoyancy_goal: float) -> float:
	var print_status := false
	
	var data : BoatHull.BoatCalculationData
	var x_fully_submerged := -10.0  # Start fully submerged
	var x_above_water := 10.0       # Start above water

	# Evaluate fully submerged
	calculation_boat.position.y = x_fully_submerged
	data = calculation_boat.hull.calculate_all()
	var f_fully_submerged := data.buoyancy_force.y - buoyancy_goal
	if print_status:
		print("Fully submerged (x = ", x_fully_submerged, "): buoyancy_force = ", data.buoyancy_force.y, ", error = ", f_fully_submerged)

	# Evaluate above water
	calculation_boat.position.y = x_above_water
	data = calculation_boat.hull.calculate_all()
	var f_above_water := data.buoyancy_force.y - buoyancy_goal
	if print_status:
		print("Above water (x = ", x_above_water, "): buoyancy_force = ", data.buoyancy_force.y, ", error = ", f_above_water)

	# If both are above or below, the goal is not achievable
	if f_fully_submerged * f_above_water > 0:
		if print_status:
			print("Error: Buoyancy goal not achievable with current hull!")
		return -999.0  # Fallback

	# Bisection method
	var x0 := x_fully_submerged
	var x1 := x_above_water
	var f0 := f_fully_submerged
	var max_iterations := 20
	var tolerance := 0.001

	for i in range(max_iterations):
		var x2 := (x0 + x1) / 2
		calculation_boat.position.y = x2
		data = calculation_boat.hull.calculate_all()
		var f1 := data.buoyancy_force.y - buoyancy_goal
		if print_status:
			print("Iteration ", i, ": Tried x = ", x2, ", buoyancy_force = ", data.buoyancy_force.y, ", error = ", f1)

		if abs(x2 - x1) < tolerance:
			if print_status:
				print("Converged to x = ", x2, " in ", i+1, " steps")
			return calculation_boat.position.y

		if f1 * f0 < 0:
			x1 = x2
		else:
			x0 = x2
			f0 = f1
	if print_status:
		print("Max iterations reached.")
	return calculation_boat.position.y
