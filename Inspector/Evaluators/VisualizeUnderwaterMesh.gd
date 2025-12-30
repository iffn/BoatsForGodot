extends Node

class_name VisualizeUnderwaterMesh

@export var boat_view : BoatView
var calculation_boat : BoatController:
	get:
		return boat_view.linked_boat

@export var visualization : MeshInstance3D

func update_underwater_mesh() -> void:
	var result := calculation_boat.hull.calculate_all()
	calculation_boat.hull.assign_underwater_mesh(visualization, result.triangles_below_water)
