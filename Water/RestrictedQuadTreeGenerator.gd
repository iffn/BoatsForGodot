extends MeshInstance3D

## Configuration
@export var plane_size: float = 1.0
@export_range(1, 100) var grid_resolution: int = 10 

@export var inner_radius : float = 1.0
@export var side_quad_count : int = 5
@export var depth : int = 2

@export var regenerate_button: bool = false:
	set(value):
		generate_mesh()

var _surface_tool: SurfaceTool
	
func generate_mesh() -> void:
	# Initialize SurfaceTool
	_surface_tool = SurfaceTool.new()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := 0
	
	# Generate base grid
	if true:
		var grid_generator = UniformGridGenerator.new(
			plane_size, 
			grid_resolution
		)
		vertices += grid_generator.vertices.size()
		for vertex in grid_generator.vertices:
			_surface_tool.add_vertex(vertex)
			
		for index in grid_generator.indices:
			_surface_tool.add_index(index)
	
	# Generate ring
	if true:
		var ring_generator = QuadraticRingGenerator.new(
			inner_radius, 
			side_quad_count,
			depth,
			vertices
		)
		vertices += ring_generator.indices.size() - 1
		for vertex in ring_generator.vertices:
			_surface_tool.add_vertex(vertex)
		for index in ring_generator.indices:
			_surface_tool.add_index(index)
	
	# Finalize Mesh
	_surface_tool.generate_normals()
	self.mesh = _surface_tool.commit()

func generate_center():
	var generator = UniformGridGenerator.new(
		plane_size, 
		grid_resolution
	)
	
	for vertex in generator.vertices:
		_surface_tool.add_vertex(vertex)
		
	for index in generator.indices:
		_surface_tool.add_index(index)

func generate_ring():
	var generator = QuadraticRingGenerator.new(
		inner_radius, 
		side_quad_count,
		depth,
		0
	)
	
	# Debug perimiter. Incease scale to test
	var debug_scale := 0.0
	for i in range(generator.inner_perimeter_indices.size()):
		generator.vertices[generator.inner_perimeter_indices[i]].y += i * debug_scale
	
	for i in range(generator.outer_perimeter_indices.size()):
		generator.vertices[generator.outer_perimeter_indices[i]].y += i * debug_scale
	
	for vertex in generator.vertices:
		_surface_tool.add_vertex(vertex)
		
	for index in generator.indices:
		_surface_tool.add_index(index)

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

class QuadraticRingGenerator:
	var vertices: PackedVector3Array = []
	var indices: PackedInt32Array = []
	
	var inner_perimeter_indices: PackedInt32Array = []
	var outer_perimeter_indices: PackedInt32Array = []
	
	var inner_radius: float
	var outer_radius: float   # Calculated internally
	var side_quad_count: int  # Total quads along one side of the large square grid
	var depth_count: int      # The number of quads spanning the ring's width (ring loops)
	var index_offset: int

	var vertex_count_per_side: int # n
	var grid_to_vertex_index_map: Dictionary = {}

	func _init(p_inner_radius: float, p_side_quad_count: int, p_depth_count: int, p_index_offset: int):
		inner_radius = p_inner_radius
		side_quad_count = p_side_quad_count
		depth_count = p_depth_count
		index_offset = p_index_offset
		side_quad_count = max(1, side_quad_count)
		depth_count = max(1, depth_count)
		vertex_count_per_side = side_quad_count + 1
		
		var hole_quad_count = side_quad_count - (2 * depth_count)
		assert(hole_quad_count >= 1, "Ring depth_count is too large; it should be less than half of side_quad_count.")
		outer_radius = inner_radius * (float(side_quad_count) / float(hole_quad_count))
		
		var n = vertex_count_per_side
		var current_vertex_count = 0 
		var total_size = outer_radius * 2.0
		var total_step = total_size / float(n - 1)
		var internal_hole_radius = inner_radius 
		
		# Vertices
		for z_index in range(n):
			for x_index in range(n):
				
				var raw_x = float(x_index) * total_step - outer_radius
				var raw_z = float(z_index) * total_step - outer_radius
				
				var vertex_pos: Vector3 = Vector3(raw_x, 0.0, raw_z)
				
				var x_abs = abs(raw_x)
				var z_abs = abs(raw_z)
				var max_abs = max(x_abs, z_abs)
				
				var grid_index = (z_index * n) + x_index
				
				if max_abs >= internal_hole_radius and max_abs <= outer_radius:
					vertices.push_back(vertex_pos)
					
					grid_to_vertex_index_map[grid_index] = current_vertex_count
					current_vertex_count += 1
					
				else:
					grid_to_vertex_index_map[grid_index] = -1
		
		# Indices
		var resolution = side_quad_count 
		for z_quad in range(resolution):
			for x_quad in range(resolution):
				var index_top_left = (z_quad * n) + x_quad
				
				var grid_v0 = index_top_left
				var grid_v1 = index_top_left + 1
				var grid_v2 = index_top_left + n
				var grid_v3 = index_top_left + n + 1
				
				var v0_local_index = grid_to_vertex_index_map.get(grid_v0, -1)
				var v1_local_index = grid_to_vertex_index_map.get(grid_v1, -1)
				var v2_local_index = grid_to_vertex_index_map.get(grid_v2, -1)
				var v3_local_index = grid_to_vertex_index_map.get(grid_v3, -1)
				
				if v0_local_index == -1 or v1_local_index == -1 or v2_local_index == -1 or v3_local_index == -1:
					continue
				
				var v0 = v0_local_index + index_offset
				var v1 = v1_local_index + index_offset
				var v2 = v2_local_index + index_offset
				var v3 = v3_local_index + index_offset
				
				indices.push_back(v3)
				indices.push_back(v2)
				indices.push_back(v0)
				
				indices.push_back(v1)
				indices.push_back(v3)
				indices.push_back(v0)
		
		# Perimiter going clockwise
		inner_perimeter_indices.clear()
		outer_perimeter_indices.clear()

		var get_final_index = func(z: int, x: int):
			var grid_index = (z * n) + x
			var local_index = grid_to_vertex_index_map.get(grid_index, -1)
			if local_index != -1:
				return local_index + index_offset
			return -1
		
		# Inner perimiter
		var inner_top_z = depth_count
		var inner_bottom_z = resolution - depth_count
		var inner_left_x = depth_count
		var inner_right_x = resolution - depth_count
		
		# Top Inner Edge
		for x in range(inner_left_x, inner_right_x + 1):
			var final_index = get_final_index.call(inner_top_z, x)
			inner_perimeter_indices.push_back(final_index)
			
		# Right Inner Edge
		for z in range(inner_top_z + 1, inner_bottom_z):
			var final_index = get_final_index.call(z, inner_right_x)
			inner_perimeter_indices.push_back(final_index)
				
		# Bottom Inner Edge
		for x in range(inner_right_x, inner_left_x - 1, -1):
			var final_index = get_final_index.call(inner_bottom_z, x)
			inner_perimeter_indices.push_back(final_index)
			
		# Left Inner Edge
		for z in range(inner_bottom_z - 1, inner_top_z, -1):
			var final_index = get_final_index.call(z, inner_left_x)
			inner_perimeter_indices.push_back(final_index)
		
		# Outer Perimeter
		var outer_top_z = 0
		var outer_bottom_z = resolution
		var outer_left_x = 0
		var outer_right_x = resolution
		
		# Top Outer Edge
		for x in range(outer_left_x, outer_right_x + 1):
			var final_index = get_final_index.call(outer_top_z, x)
			outer_perimeter_indices.push_back(final_index)
			
		# Right Outer Edge
		for z in range(outer_top_z + 1, outer_bottom_z):
			var final_index = get_final_index.call(z, outer_right_x)
			outer_perimeter_indices.push_back(final_index)
				
		# Bottom Outer Edge
		for x in range(outer_right_x, outer_left_x - 1, -1):
			var final_index = get_final_index.call(outer_bottom_z, x)
			outer_perimeter_indices.push_back(final_index)
			
		# Left Outer Edge
		for z in range(outer_bottom_z - 1, outer_top_z, -1):
			var final_index = get_final_index.call(z, outer_left_x)
			outer_perimeter_indices.push_back(final_index)
