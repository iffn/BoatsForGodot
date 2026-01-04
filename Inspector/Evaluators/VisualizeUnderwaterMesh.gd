extends Node

class_name VisualizeUnderwaterMesh

@export var boat_syncronizer : BoatEditSyncronizer
var calculation_boat : BoatController:
	get:
		return boat_syncronizer.calculation_boat

@export var visualization : MeshInstance3D

func _ready() -> void:
	boat_syncronizer.boat_modified.connect(update_underwater_mesh)

func update_underwater_mesh() -> void:
	var result := calculation_boat.hull.calculate_all()
	calculation_boat.hull.assign_underwater_mesh(visualization, result.triangles_below_water)
