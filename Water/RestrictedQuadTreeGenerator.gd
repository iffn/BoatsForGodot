extends MeshInstance3D

@export var plane_size: float = 1.0

@export var regenerate_button: bool = false:
	set(value):
		generate_mesh()

var surface_tool: SurfaceTool

func generate_mesh() -> void:
	# 1. Initialize SurfaceTool
	surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_size = plane_size / 2.0
	
	# Add vertices
	var all_vertices = [
		Vector3(-half_size, 0.0, -half_size),
		Vector3(0.0, 0.0, -half_size),
		Vector3(half_size, 0.0, -half_size),
		
		Vector3(-half_size, 0.0, 0.0),
		Vector3(0.0, 0.0, 0.0),
		Vector3(half_size, 0.0, 0.0),
		
		Vector3(-half_size, 0.0, half_size),
		Vector3(0.0, 0.0, half_size),
		Vector3(half_size, 0.0, half_size)
	]
	
	for vertex in all_vertices:
		surface_tool.add_vertex(vertex)
	
	# Add triangles
	var indices: Array = [
		4, 3, 0,    1, 4, 0,
		5, 4, 1,    2, 5, 1,
		7, 6, 3,    4, 7, 3, 
		8, 7, 4,    5, 8, 4
	]
	
	for index in indices:
		surface_tool.add_index(index)

	# 5. Finalize Mesh
	surface_tool.generate_normals()
	
	self.mesh = surface_tool.commit()
	print("4-Quad Mesh regenerated successfully. Plane Size: %f" % plane_size)
