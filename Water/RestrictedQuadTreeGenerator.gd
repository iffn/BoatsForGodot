extends MeshInstance3D

@export var plane_size: float = 1.0
@export_range(1, 100) var grid_resolution: int = 10 

@export var regenerate_button: bool = false:
	set(value):
		generate_mesh()

var surface_tool: SurfaceTool

func generate_mesh() -> void:
	# 1. Initialize SurfaceTool
	surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_size = plane_size / 2.0
	var step_size = plane_size / float(grid_resolution)
	
	var vertex_count_per_side = grid_resolution + 1

	# Generate Vertices
	for z_index in range(vertex_count_per_side):
		for x_index in range(vertex_count_per_side):
			var x = float(x_index) * step_size - half_size
			var z = float(z_index) * step_size - half_size
			
			var vertex = Vector3(x, 0.0, z)
			surface_tool.add_vertex(vertex)

	# Generate Indices
	for z_quad in range(grid_resolution):
		for x_quad in range(grid_resolution):
			var i_tl = (z_quad * vertex_count_per_side) + x_quad
			
			var v0 = i_tl                         
			var v1 = i_tl + 1                     
			var v2 = i_tl + vertex_count_per_side 
			var v3 = i_tl + vertex_count_per_side + 1 

			# Triangulation (CW for upwards normal)
			surface_tool.add_index(v3)
			surface_tool.add_index(v2)
			surface_tool.add_index(v0)
			
			surface_tool.add_index(v1)
			surface_tool.add_index(v3)
			surface_tool.add_index(v0)

	# Finalize Mesh
	surface_tool.generate_normals()
	
	self.mesh = surface_tool.commit()
