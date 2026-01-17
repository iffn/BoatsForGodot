extends Node

@export var boat_syncronizer : BoatEditSyncronizer
var calculation_boat : BoatController:
	get:
		return boat_syncronizer.calculation_boat

@export var _update_button: Button
@export var _basic_geometry_name_holder: Control 
@export var _basic_geometry_output_holder: Control 

func _ready() -> void:
	boat_syncronizer.connect_boat_modified_calculated(update_geometry_info)

func evaluate_geometry():
	var data := calculation_boat.hull.calculate_all()
	update_geometry_info(data)

func update_geometry_info(data: BoatHull.BoatCalculationData):
	var names := _basic_geometry_name_holder.find_children("*", "Label")
	var output := _basic_geometry_output_holder.find_children("*", "Label")
	
	var i = 0
	
	var bounding_box := calculation_boat.hull.bounding_box
	
	names[i].text = "Length overall"
	output[i].text = str(bounding_box.size.z).pad_decimals(2)
	i+=1
	
	names[i].text = "Beam"
	output[i].text = str(bounding_box.size.x).pad_decimals(2)
	i+=1
	
	names[i].text = "Length at the waterline"
	output[i].text = str(data.water_plane_size_XZ.y).pad_decimals(2)
	i+=1
	
	names[i].text = "Beam at the waterline"
	output[i].text = str(data.water_plane_size_XZ.x).pad_decimals(2)
	i+=1
	
	names[i].text = "Depth"
	output[i].text = str(bounding_box.size.y).pad_decimals(2)
	i+=1
	
	names[i].text = "Draft"
	output[i].text = str(data.draft).pad_decimals(2)
	i+=1
	
	names[i].text = "Freeboard"
	output[i].text = str(bounding_box.size.y - data.draft).pad_decimals(2)
	i+=1
	
	_update_button.text = "Up to date"
