extends Node

class_name BoatDrivingSceneManager

@export var save_and_load : SaveAndLoad

var _scene_manager : SceneManager

func setup_with_model(the_scene_manager : SceneManager, glb_buffer: PackedByteArray):
	setup(the_scene_manager)
	save_and_load.load_boat_from_buffer(glb_buffer)

func setup(the_scene_manager : SceneManager):
	_scene_manager = the_scene_manager

func switch_to_inspector_scene():
	var glb_buffer := save_and_load.get_boat_as_glb_buffer()
	_scene_manager.switch_to_inspector_scene(glb_buffer)
