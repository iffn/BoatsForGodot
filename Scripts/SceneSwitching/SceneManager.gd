extends Node

class_name SceneManager

@export var inspector_scene_source: PackedScene
@export var driving_scene_source: PackedScene
@export var current_scene: Node

func _ready():
	if current_scene is BoatDrivingSceneManager:
		var driving_scene = current_scene as BoatDrivingSceneManager
		driving_scene.setup(self)
	elif current_scene is InspectorSceneManager:
		var inspector_scene = current_scene as InspectorSceneManager
		inspector_scene.setup(self)

func switch_to_inspector_scene(glb_buffer: PackedByteArray):
	current_scene.queue_free()
	
	current_scene = inspector_scene_source.instantiate()
	add_child(current_scene)
	
	if current_scene is InspectorSceneManager:
		var driving_scene = current_scene as InspectorSceneManager
		driving_scene.setup_with_model(self, glb_buffer)


func switch_to_driving_scene(glb_buffer: PackedByteArray):
	current_scene.queue_free()
	
	current_scene = driving_scene_source.instantiate()
	add_child(current_scene)
	
	if current_scene is BoatDrivingSceneManager:
		var driving_scene = current_scene as BoatDrivingSceneManager
		driving_scene.setup_with_model(self, glb_buffer)
