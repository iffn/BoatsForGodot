extends Node

class_name SaveAndLoad

@export var boat_syncronizer : BoatEditSyncronizer
@export var boat: BoatController
@export var import_report : Label
@export var save_or_download_button : Button

func output_last_load_report():
	if import_report == null || boat_syncronizer == null:
		return
	var report := boat_syncronizer.calculation_boat.last_report
	var output := ""
	var separator := import_report.paragraph_separator.c_unescape()
	output += separator.join(report)
	import_report.text = output

func _ready():
	get_tree().get_root().files_dropped.connect(_on_files_dropped)
	call_deferred("output_last_load_report")
	if save_or_download_button:
		if OS.has_feature("web"):
			save_or_download_button.text = "Download .glb"
		else:
			save_or_download_button.text = "Save as .glb"

func convert_node_to_glb_buffer(node: Node) -> PackedByteArray:
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	gltf_doc.append_from_scene(node, gltf_state)
	return gltf_doc.generate_buffer(gltf_state)

func convert_glb_buffer_to_node(buffer: PackedByteArray) -> Node:
	if buffer.is_empty():
		return null
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var error = gltf_doc.append_from_buffer(buffer, "", gltf_state)
	if error == OK:
		return gltf_doc.generate_scene(gltf_state)
	return null

func get_boat_as_glb_buffer() -> PackedByteArray:
	boat.prepare_boat_model_for_export()
	return convert_node_to_glb_buffer(boat.boat_model)

func load_boat_from_buffer(buffer: PackedByteArray):
	var boat_model := convert_glb_buffer_to_node(buffer) as Node3D
	_setup_boat(boat_model)

func _setup_boat(boat_model: Node3D):
	if boat_model == null:
		return
	boat.add_child(boat_model)
	boat.replace_boat_model(boat_model)
	if boat_syncronizer:
		boat_syncronizer.emit_signals()
	output_last_load_report()

func _on_files_dropped(files: PackedStringArray):
	if files[0].ends_with(".glb"):
		load_glb_at_runtime(files[0])

func load_glb_at_runtime(path: String):
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	var error = gltf_doc.append_from_file(path, gltf_state)
	if error == OK:
		var boat_model := gltf_doc.generate_scene(gltf_state) as Node3D
		_setup_boat(boat_model)

func save_or_download_boat():
	boat.prepare_boat_model_for_export()
	_save_or_download_glb(boat.boat_model)

func _save_or_download_glb(node : Node):
	var buffer: = convert_node_to_glb_buffer(node)
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(buffer, node.name + ".glb", "model/gltf-binary")
	else:
		# Use a lambda or a reference to a function to handle the result
		var on_file_selected = func(status: bool, selected_paths: PackedStringArray, _filter_index: int):
			if status and selected_paths.size() > 0:
				var path = selected_paths[0]
				var file = FileAccess.open(path, FileAccess.WRITE)
				if file:
					file.store_buffer(buffer)
					file.close()
					print("Saved GLB to: ", path)

		# Open the native OS Save File dialog
		DisplayServer.file_dialog_show(
			"Save Your Model",      # Title
			"",                     # Initial directory (empty is default)
			node.name + ".glb",          # Default filename
			false,                  # Boolean: Show folders (false for file save)
			DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, 
			PackedStringArray(["*.glb ; glTF Binary"]), 
			on_file_selected        # The callback function defined above
		)
