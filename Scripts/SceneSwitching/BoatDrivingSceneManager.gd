extends Node

class_name BoatDrivingSceneManager

var _scene_manager : SceneManager

func setup(the_scene_manager : SceneManager):
	_scene_manager = the_scene_manager

func switch_to_inspector_scene():
	_scene_manager.switch_to_inspector_scene()
