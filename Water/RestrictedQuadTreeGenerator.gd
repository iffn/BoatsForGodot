extends MeshInstance3D

## Configuration
@export var plane_size: float = 1.0
@export_range(1, 100) var grid_resolution: int = 10 

@export var regenerate_button: bool = false:
	set(value):
		generate_mesh()

var _surface_tool: SurfaceTool

func generate_mesh() -> void:
	# Initialize SurfaceTool
	_surface_tool = SurfaceTool.new()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Instantiate and run the generator class (generation happens in _init)
	var generator = UniformGridGenerator.new(
		plane_size, 
		grid_resolution
	)
	
	# Debug perimiter. Incease scale to test
	var debug_scale := 0.0
	for i in range(generator.perimeter_indices.size()):
		generator.vertices[generator.perimeter_indices[i]].y += i * debug_scale
	
	# Transfer data from the class arrays to the SurfaceTool
	for vertex in generator.vertices:
		_surface_tool.add_vertex(vertex)
		
	for index in generator.indices:
		_surface_tool.add_index(index)

	# Finalize Mesh
	_surface_tool.generate_normals()
	self.mesh = _surface_tool.commit()

class UniformGridGenerator:
	var plane_size: float
	var grid_resolution: int
	
	# Public arrays to store the generated mesh data
	var vertices: PackedVector3Array = []
	var indices: PackedInt32Array = []
	var perimeter_indices: PackedInt32Array = [] 
	
	var _half_size: float
	var _step_size: float
	var _vertex_count_per_side: int

	# Constructor
	func _init(size: float, resolution: int):
		plane_size = size
		grid_resolution = resolution
		
		_half_size = plane_size / 2.0
		_step_size = plane_size / float(grid_resolution)
		_vertex_count_per_side = grid_resolution + 1
		
		var n = _vertex_count_per_side
		
		# Vertices
		for z_index in range(n):
			for x_index in range(n):
				var x = float(x_index) * _step_size - _half_size
				var z = float(z_index) * _step_size - _half_size
				
				var vertex = Vector3(x, 0.0, z)
				vertices.push_back(vertex)
		
		# Indices
		for z_quad in range(grid_resolution):
			for x_quad in range(grid_resolution):
				var index_top_left = (z_quad * n) + x_quad
				
				var v0 = index_top_left
				var v1 = index_top_left + 1
				var v2 = index_top_left + n
				var v3 = index_top_left + n + 1
				
				indices.push_back(v3)
				indices.push_back(v2)
				indices.push_back(v0)
				
				indices.push_back(v1)
				indices.push_back(v3)
				indices.push_back(v0)
		
		# Perimiter indices:
		
		# Top Edge (Left to Right)
		for i in range(n):
			perimeter_indices.push_back(i)
			
		# Right Edge (Top to Bottom)
		for i in range(1, n):
			# Index of the rightmost vertex in row i
			var index = i * n + (n - 1)
			perimeter_indices.push_back(index)
			
		# Bottom Edge (Right to Left)
		for i in range(n * n - 2, n * n - n, -1):
			perimeter_indices.push_back(i)
			
		# Left Edge (Bottom to Top)
		for i in range(n - 1, 0, -1):
			var index = i * n
			perimeter_indices.push_back(index)
