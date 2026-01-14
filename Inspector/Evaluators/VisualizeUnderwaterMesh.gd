extends Node

class_name VisualizeUnderwaterMesh

@export var boat_syncronizer : BoatEditSyncronizer
var calculation_boat : BoatController:
	get:
		return boat_syncronizer.calculation_boat

@export var visualization : MeshInstance3D

func _ready() -> void:
	boat_syncronizer.connect_boat_modified_calculated(update_underwater_mesh)

func update_underwater_mesh(data: BoatHull.BoatCalculationData) -> void:
	calculation_boat.hull.assign_underwater_mesh(visualization, data.triangles_below_water)
