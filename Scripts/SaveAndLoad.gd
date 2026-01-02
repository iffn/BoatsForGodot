extends Node

@export var boat : BoatController

func _ready():
	# Connect to the engine's global signal for dropped files
	get_tree().get_root().files_dropped.connect(_on_files_dropped)

func _on_files_dropped(files: PackedStringArray):
	if files[0].ends_with(".glb"):
		load_glb_at_runtime(files[0])

func load_glb_at_runtime(path: String):
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	# Load the file data into the state
	var error = gltf_doc.append_from_file(path, gltf_state)
	if error == OK:
		# Generate the 3D node
		var boat_model := gltf_doc.generate_scene(gltf_state) as Node3D
		boat.add_child(boat_model)
		boat.replace_boat_model(boat_model)
		
