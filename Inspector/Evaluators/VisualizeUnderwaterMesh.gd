extends Node

class_name VisualizeUnderwaterMesh

@export var calculation_boat : BoatController
@export var visualization : MeshInstance3D

func update_underwater_mesh() -> void:
	var result := calculation_boat.hull.calculate_all()
	calculation_boat.hull.assign_underwater_mesh(visualization, result.triangles_below_water)
	print("Time: ", Time.get_ticks_msec())
