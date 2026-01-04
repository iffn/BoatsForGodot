extends Node

class_name BaseBoatPlot

@export var boat_syncronizer : BoatEditSyncronizer
var calculation_boat : BoatController:
	get:
		return boat_syncronizer.calculation_boat

@export var update_button : Button

func boat_modified():
	update_button.text = "Out of date. Click to update"

func _ready() -> void:
	boat_syncronizer.boat_modified.connect(boat_modified)
	if not update_button.pressed.is_connected(plot_graph):
		update_button.pressed.connect(plot_graph)

func plot_graph():
	update_button.text = "Graph up to date"
