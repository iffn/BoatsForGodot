extends Node

class_name BoatHull

# Inspired by:
# https://www.gamedeveloper.com/programming/water-interaction-model-for-boats-in-video-games
# https://www.habrador.com/tutorials/unity-boat-tutorial
# https://github.com/iffn/iffnsBoatsForVRChat/blob/main/Scripts/HullCalculator.cs

@export var drag_coefficient : float = 0.05
@export var drag_multiplier : float  = 1.0
@export var buoyancy_multiplier : float  = 1.0
@export var hull_mesh: MeshInstance3D
@export var rigidbody: RigidBody3D
@export var water_level: WaterLevelProvider

@export var linear_velocity_output : Label
@export var angular_velocity_output : Label
@export var buoyancy_force_output : Label
@export var drag_force_output : Label
@export var mass_output : Label

var mesh_vertices_local : Array[Vector3]
var mesh_triangles : Array[MeshTriangle]
var mesh_vertices_world : Array[Vector3]
var distances_to_water : Array[float]


var bounding_box : AABB:
	get:
		return hull_mesh.get_aabb()

func _ready() -> void:
	convert_mesh()

func _physics_process(delta: float) -> void:
	apply_to_rigidbody()

func convert_mesh():
	mesh_vertices_local = []
	mesh_triangles = []
	mesh_vertices_world = []
	distances_to_water = []
	
	var mesh := hull_mesh.mesh
	var mesh_data_tool := MeshDataTool.new()
	mesh_data_tool.create_from_surface(mesh, 0)
	
	for v_index in range(mesh_data_tool.get_vertex_count()):
		var pos = mesh_data_tool.get_vertex(v_index)
		mesh_vertices_local.append(pos)
	
	mesh_vertices_world.resize(mesh_vertices_local.size())
	distances_to_water.resize(mesh_vertices_local.size())
	
	for face_index in range(mesh_data_tool.get_face_count()):
		var i0 := mesh_data_tool.get_face_vertex(face_index, 0)
		var i1 := mesh_data_tool.get_face_vertex(face_index, 1)
		var i2 := mesh_data_tool.get_face_vertex(face_index, 2)
		
		var normal := mesh_data_tool.get_face_normal(face_index)
		var triangle := MeshTriangle.new(mesh_vertices_local, mesh_vertices_world, distances_to_water, i0, i1, i2, normal)
		mesh_triangles.append(triangle)
	
	mesh_data_tool.clear()

func update_mesh_positions():
	var hull_transform := hull_mesh.global_transform
	
	for i in range(mesh_vertices_local.size()):
		mesh_vertices_world[i] = hull_transform * mesh_vertices_world[i]
		distances_to_water[i] = water_level.get_distance_to_water(mesh_vertices_world[i])
	
	for triangle in mesh_triangles:
		triangle.normal_world = (hull_transform.basis * triangle.normal_local).normalized()

func apply_to_rigidbody():
	var triangles_below_water : Array[BelowWaterTriangle] = []
	
	update_mesh_positions()
	
	for triangle in mesh_triangles:
		assign_below_water(triangle, triangles_below_water)
	
	var velocity_world := rigidbody.linear_velocity
	
	for triangle in triangles_below_water:
		# Buoyancy
		#var application_position := triangle.geometric_center_world - rigidbody.global_position
		var application_position := triangle.hydrostatic_center_world - rigidbody.global_position
		var application_force := buoyancy_multiplier * triangle.static_pressure_force_world
		application_force.x = 0.0
		application_force.z = 0.0
		rigidbody.apply_force(application_force, application_position)
		
		var drag = drag_multiplier * triangle.world_drag_force(velocity_world, drag_coefficient)
		rigidbody.apply_force(drag)

func calculate_all() -> BoatCalculationData:
	var output := BoatCalculationData.new()
	var triangles_below_water : Array[BelowWaterTriangle] = []
	var waterline_points : Array[Vector3] = []
	
	update_mesh_positions()
	
	for triangle in mesh_triangles:
		assign_below_water(triangle, triangles_below_water)
		assign_water_line(triangle, waterline_points)
	
	var velocity_world := rigidbody.linear_velocity
	
	var water_x_max := -INF
	var water_x_min := INF
	var water_z_max := -INF
	var water_z_min := INF
	var water_y_min := INF
	
	var center_of_buoyancy_world_additive := Vector3(0,0,0)
	var displaced_volume_additive := 0.0
	var water_line_point := Vector3(0,0,0)
	water_line_point.y = water_level.get_distance_to_water(water_line_point)
	
	for triangle in triangles_below_water:
		var a := triangle.v0_world - water_line_point;
		var b := triangle.v1_world - water_line_point;
		var c := triangle.v2_world - water_line_point;
		
		var tetrahedron_volume := (-0.1666666667) * a.dot(b.cross(c));
		var tetrahedron_center := 0.25 * (triangle.v0_world + triangle.v1_world + triangle.v2_world + water_line_point)
		
		displaced_volume_additive += tetrahedron_volume
		center_of_buoyancy_world_additive += tetrahedron_volume * tetrahedron_center	
		
		var drag = drag_multiplier * triangle.world_drag_force(velocity_world, drag_coefficient)
		
		output.buoyancy_force += triangle.static_pressure_force_world
		output.drag_force += drag
		water_y_min = min(triangle.v0_world.y, water_y_min)
		water_y_min = min(triangle.v1_world.y, water_y_min)
		water_y_min = min(triangle.v2_world.y, water_y_min)
	
	for point in waterline_points:
		water_x_max = max(point.x, water_x_max)
		water_x_min = min(point.x, water_x_min)
		water_z_max = max(point.z, water_z_max)
		water_z_min = min(point.z, water_z_min)
	
	if(triangles_below_water.size() > 0):
		output.water_plane_size_XZ = Vector2(water_x_max - water_x_min, water_z_max - water_z_min)
		output.draft = -water_y_min
		output.triangles_below_water = triangles_below_water
		output.waterline_points = waterline_points
		center_of_buoyancy_world_additive = (1.0/displaced_volume_additive) * center_of_buoyancy_world_additive
		output.center_of_buoyancy_world = center_of_buoyancy_world_additive
		output.displaced_volume = displaced_volume_additive
	
	return output

func calculate_buoyancy_force() -> Vector3:
	var output := Vector3(0,0,0)
	var triangles_below_water : Array[BelowWaterTriangle] = []
	
	for triangle in mesh_triangles:
		triangle.update_world_positions(hull_mesh.global_transform)
		assign_below_water(triangle, triangles_below_water)
	
	for triangle in triangles_below_water:
		output += triangle.static_pressure_force_world
	
	return output

func assign_water_line(triangle: MeshTriangle, water_line: Array[Vector3]) -> void:
	var v0 := triangle.v0_world
	var v1 := triangle.v1_world
	var v2 := triangle.v2_world
	
	var distance_to_water_0 := water_level.get_distance_to_water(v0)
	var distance_to_water_1 := water_level.get_distance_to_water(v1)
	var distance_to_water_2 := water_level.get_distance_to_water(v2)
	
	var above_water_counter := 0
	
	if(distance_to_water_0 > 0): above_water_counter += 1
	if(distance_to_water_1 > 0): above_water_counter += 1
	if(distance_to_water_2 > 0): above_water_counter += 1
	
	if(above_water_counter == 0):
		# Below water not needed
		pass
	elif(above_water_counter == 1):
		var high_point : Vector3
		var low_point_1 : Vector3
		var low_point_2 : Vector3
		
		var distance_to_water_high : float
		var distance_to_water_low_1 : float
		var distance_to_water_low_2 : float
		
		if v0.y > v1.y:
			if v0.y > v2.y:
				# Order tested
				high_point = v0
				low_point_1 = v1
				low_point_2 = v2
				distance_to_water_high = distance_to_water_0
				distance_to_water_low_1 = distance_to_water_1
				distance_to_water_low_2 = distance_to_water_2
			else:
				# Order not tested
				high_point = v2
				low_point_1 = v0
				low_point_2 = v1
				distance_to_water_high = distance_to_water_2
				distance_to_water_low_1 = distance_to_water_0
				distance_to_water_low_2 = distance_to_water_1
		else:
			if v1.y > v2.y:
				# Order tested
				high_point = v1
				low_point_1 = v2
				low_point_2 = v0
				distance_to_water_high = distance_to_water_1
				distance_to_water_low_1 = distance_to_water_2
				distance_to_water_low_2 = distance_to_water_0
			else:
				# Order not tested
				high_point = v2
				low_point_1 = v0
				low_point_2 = v1
				distance_to_water_high = distance_to_water_2
				distance_to_water_low_1 = distance_to_water_0
				distance_to_water_low_2 = distance_to_water_1
		
		var between_point_1 = lerp(high_point, low_point_1, distance_to_water_high / (distance_to_water_high - distance_to_water_low_1))
		var between_point_2 = lerp(high_point, low_point_2, distance_to_water_high / (distance_to_water_high - distance_to_water_low_2))
		water_line.append(between_point_1)
		water_line.append(between_point_2)
		
	elif(above_water_counter == 2):
		var low_point : Vector3
		var high_point_1 : Vector3
		var high_point_2 : Vector3
		var distance_to_water_low : float
		var distance_to_water_high_1 : float
		var distance_to_water_high_2 : float
		
		if v0.y < v1.y:
			if v0.y < v2.y:
				# Order tested
				low_point = v0
				high_point_1 = v1
				high_point_2 = v2
				distance_to_water_low = distance_to_water_0
				distance_to_water_high_1 = distance_to_water_1
				distance_to_water_high_2 = distance_to_water_2
			else:
				# Order not tested
				low_point = v2
				high_point_1 = v0
				high_point_2 = v1
				distance_to_water_low = distance_to_water_2
				distance_to_water_high_1 = distance_to_water_0
				distance_to_water_high_2 = distance_to_water_1
		else:
			if v1.y < v2.y:
				# Order tested
				low_point = v1
				high_point_1 = v2
				high_point_2 = v0
				distance_to_water_low = distance_to_water_1
				distance_to_water_high_1 = distance_to_water_2
				distance_to_water_high_2 = distance_to_water_0
			else:
				# Order not tested
				low_point = v2
				high_point_1 = v0
				high_point_2 = v1
				distance_to_water_low = distance_to_water_2
				distance_to_water_high_1 = distance_to_water_0
				distance_to_water_high_2 = distance_to_water_1
		
		var between_point_1 = lerp(high_point_1, low_point, distance_to_water_high_1 / (distance_to_water_high_1 - distance_to_water_low))
		var between_point_2 = lerp(high_point_2, low_point, distance_to_water_high_2 / (distance_to_water_high_2 - distance_to_water_low))
		water_line.append(between_point_1)
		water_line.append(between_point_2)
	else:
		pass

func assign_below_water(triangle: MeshTriangle, below_water: Array[BelowWaterTriangle]) -> void:
	var v0 := triangle.v0_world
	var v1 := triangle.v1_world
	var v2 := triangle.v2_world
	var normal := triangle.normal_world
	
	var h0 := triangle.distance_to_water_0
	var h1 := triangle.distance_to_water_1
	var h2 := triangle.distance_to_water_2
	
	var above_water_counter := 0
	
	if(h0 > 0): above_water_counter += 1
	if(h1 > 0): above_water_counter += 1
	if(h2 > 0): above_water_counter += 1
	
	if(above_water_counter == 0):
		below_water.append(BelowWaterTriangle.create_from_triangle(triangle))
	
	elif(above_water_counter == 1):
		var high_point : Vector3
		var low_point_1 : Vector3
		var low_point_2 : Vector3
		
		var h_high : float
		var h_low_1 : float
		var h_low_2 : float
		
		if h0 > h1:
			if h0 > h2:
				# Order tested
				high_point = v0
				low_point_1 = v1
				low_point_2 = v2
				h_high = h0
				h_low_1 = h1
				h_low_2 = h2
			else:
				# Order not tested
				high_point = v2
				low_point_1 = v0
				low_point_2 = v1
				h_high = h2
				h_low_1 = h0
				h_low_2 = h1
		else:
			if h1 > h2:
				# Order tested
				high_point = v1
				low_point_1 = v2
				low_point_2 = v0
				h_high = h1
				h_low_1 = h2
				h_low_2 = h0
			else:
				# Order not tested
				high_point = v2
				low_point_1 = v0
				low_point_2 = v1
				h_high = h2
				h_low_1 = h0
				h_low_2 = h1
		
		var lerp_1 = h_high / (h_high - h_low_1)
		var lerp_2 = h_high / (h_high - h_low_2)
		
		var between_point_1 : Vector3 = lerp(high_point, low_point_1, lerp_1)
		var between_point_2 : Vector3  = lerp(high_point, low_point_2, lerp_2)
		var h_between_1 : float = lerp(h_high, h_low_1, lerp_1)
		var h_between_2 : float = lerp(h_high, h_low_2, lerp_2)
		
		below_water.append(BelowWaterTriangle.create_from_points(low_point_1, low_point_2, between_point_1, h_low_1, h_low_2, h_between_1, normal))
		below_water.append(BelowWaterTriangle.create_from_points(low_point_2, between_point_2, between_point_1, h_low_2, h_between_2, h_between_1, normal))
		#above_water.append(AboveWaterTriangle.new(between_point_1, between_point_2, high_point, normal))
		
	elif(above_water_counter == 2):
		var low_point : Vector3
		var high_point_1 : Vector3
		var high_point_2 : Vector3
		var h_low : float
		var h_high_1 : float
		var h_high_2 : float
		
		if h0 < h1:
			if h0 < h2:
				# Order tested
				low_point = v0
				high_point_1 = v1
				high_point_2 = v2
				h_low = h0
				h_high_1 = h1
				h_high_2 = h2
			else:
				# Order not tested
				low_point = v2
				high_point_1 = v0
				high_point_2 = v1
				h_low = h2
				h_high_1 = h0
				h_high_2 = h1
		else:
			if h1 < h2:
				# Order tested
				low_point = v1
				high_point_1 = v2
				high_point_2 = v0
				h_low = h1
				h_high_1 = h2
				h_high_2 = h0
			else:
				# Order not tested
				low_point = v2
				high_point_1 = v0
				high_point_2 = v1
				h_low = h2
				h_high_1 = h0
				h_high_2 = h1
		
		var lerp_1 := h_high_1 / (h_high_1 - h_low)
		var lerp_2 := h_high_2 / (h_high_2 - h_low)
		
		var between_point_1 : Vector3 = lerp(high_point_1, low_point, lerp_1)
		var between_point_2 : Vector3 = lerp(high_point_2, low_point, lerp_2)
		var h_between_1 : float = lerp(h_high_1, h_low, lerp_1)
		var h_between_2 : float = lerp(h_high_2, h_low, lerp_2)
		
		#above_water.append(Triangle.new(low_point, between_point_2, between_point_1, true, false, normal))
		#above_water.append(Triangle.new(between_point_1, between_point_2, high_point_1, true, false, normal))
		below_water.append(BelowWaterTriangle.create_from_points(low_point, between_point_1, between_point_2, h_low, h_between_1, h_between_2, normal))
		
	else:
		#above_water.append(self)
		pass

func assign_underwater_mesh(mesh_instance : MeshInstance3D, triangles_below_water : Array[BelowWaterTriangle]):
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	print("Mesh: ", mesh_triangles.size())
	print("Underwater: ", triangles_below_water.size())
	
	for triangle in triangles_below_water:
		surface_tool.add_vertex(triangle.v0_world)
		surface_tool.add_vertex(triangle.v1_world)
		surface_tool.add_vertex(triangle.v2_world)
	
	for triangle in mesh_triangles:
		break
		surface_tool.add_vertex(triangle.v0_world)
		surface_tool.add_vertex(triangle.v1_world)
		surface_tool.add_vertex(triangle.v2_world)
	
	var array_mesh := ArrayMesh.new()
	surface_tool.commit(array_mesh)
	mesh_instance.mesh = array_mesh

func find_waterline(buoyancy_goal: float) -> float:
	var original_value := rigidbody.position.y
	
	var print_status := false
	
	var data : BoatHull.BoatCalculationData
	var x_fully_submerged := -10.0  # Start fully submerged
	var x_above_water := 10.0       # Start above water

	# Evaluate fully submerged
	rigidbody.position.y = x_fully_submerged
	data = calculate_all()
	var f_fully_submerged := data.buoyancy_force.y - buoyancy_goal
	if print_status:
		print("Fully submerged (x = ", x_fully_submerged, "): buoyancy_force = ", data.buoyancy_force.y, ", error = ", f_fully_submerged)

	# Evaluate above water
	rigidbody.position.y = x_above_water
	data = calculate_all()
	var f_above_water := data.buoyancy_force.y - buoyancy_goal
	if print_status:
		print("Above water (x = ", x_above_water, "): buoyancy_force = ", data.buoyancy_force.y, ", error = ", f_above_water)

	# If both are above or below, the goal is not achievable
	if f_fully_submerged * f_above_water > 0:
		if print_status:
			print("Error: Buoyancy goal not achievable with current hull!")
		return -999.0  # Fallback

	# Bisection method
	var x0 := x_fully_submerged
	var x1 := x_above_water
	var f0 := f_fully_submerged
	var max_iterations := 20
	var tolerance := 0.001
	
	var found := false
	
	for i in range(max_iterations):
		var x2 := (x0 + x1) / 2
		rigidbody.position.y = x2
		data = calculate_all()
		var f1 := data.buoyancy_force.y - buoyancy_goal
		if print_status:
			print("Iteration ", i, ": Tried x = ", x2, ", buoyancy_force = ", data.buoyancy_force.y, ", error = ", f1)

		if abs(x2 - x1) < tolerance:
			if print_status:
				print("Converged to x = ", x2, " in ", i+1, " steps")
			found = true
			break

		if f1 * f0 < 0:
			x1 = x2
		else:
			x0 = x2
			f0 = f1
	if !found && print_status:
		print("Max iterations reached.")
	
	var return_value := rigidbody.position.y
	rigidbody.position.y = original_value
	return return_value

class BoatCalculationData:
	var buoyancy_force : Vector3
	var drag_force: Vector3
	var water_plane_size_XZ: Vector2
	var draft: float
	var triangles_below_water : Array[BelowWaterTriangle]
	var waterline_points : Array[Vector3]
	var center_of_buoyancy_world: Vector3
	var displaced_volume: float

class MeshTriangle:
	var i0 : int
	var i1 : int
	var i2 : int
	
	var mesh_vertices_local : Array[Vector3]
	var mesh_vertices_world : Array[Vector3]
	var distances_to_water : Array[float]
	
	var v0_local : Vector3:
		get:
			return mesh_vertices_local[i0]
	var v1_local : Vector3:
		get:
			return mesh_vertices_local[i1]
	var v2_local : Vector3:
		get:
			return mesh_vertices_local[i2]
	
	var v0_world : Vector3:
		get:
			return mesh_vertices_world[i0]
	var v1_world : Vector3:
		get:
			return mesh_vertices_world[i1]
	var v2_world : Vector3:
		get:
			return mesh_vertices_world[i2]
	
	var distance_to_water_0 : float:
		get:
			return distances_to_water[i0]
	var distance_to_water_1 : float:
		get:
			return distances_to_water[i1]
	var distance_to_water_2 : float:
		get:
			return distances_to_water[i2]
	
	var normal_local : Vector3
	var normal_world : Vector3
	
	var area : float
	
	func _init(the_mesh_vertices_local : Array[Vector3], the_mesh_vertices_world : Array[Vector3], the_distances_to_water : Array[float],
			the_i0 : int, the_i1 : int, the_i2 : int, the_normal_local):
		
		mesh_vertices_local = the_mesh_vertices_local
		mesh_vertices_world = the_mesh_vertices_world
		distances_to_water = the_distances_to_water
		
		i0 = the_i0
		i1 = the_i1
		i2 = the_i2
		
		normal_local = the_normal_local
		area = get_triangle_area_from_points(v0_local, v1_local, v2_local)
	
	static func get_triangle_area_from_points(A: Vector3, B: Vector3, C: Vector3):
		# Triangle area according to sin formula:
		# A = 0.5 * a * b * sin(gamma)
		# A = Area [m^2]
		# a = Distance between B and C [m]
		# b = Distance between A and C [m]
		# gamma = angle at point C [rad]
		
		var a := B.distance_to(C)
		var b := A.distance_to(C)
		var gamma_rad := (A - C).angle_to(B - C)
		
		return 0.5 * a * b * sin(gamma_rad)

class BelowWaterTriangle:
	var v0_world : Vector3
	var v1_world : Vector3
	var v2_world : Vector3
	
	var static_pressure_force_world : Vector3
	var geometric_center_world : Vector3
	var hydrostatic_center_world : Vector3
	var area : float
	static var fluid_density := 1000
	static var gravitational_acceleration := 9.81
	
	func _init(the_v0_world: Vector3, the_v1_world: Vector3, the_v2_world, the_geometric_center_world : Vector3, the_hydrostatic_center_world : Vector3, the_static_pressure_force_world : Vector3, the_area : float):
		v0_world = the_v0_world
		v1_world = the_v1_world
		v2_world = the_v2_world
		geometric_center_world = the_geometric_center_world
		hydrostatic_center_world = the_hydrostatic_center_world
		static_pressure_force_world = the_static_pressure_force_world
		area = the_area
	
	static func calculate_hydrostatic_center_world(the_v0_world: Vector3, the_v1_world: Vector3, the_v2_world: Vector3, the_distance_to_water_0 : float, the_distance_to_water_1 : float, the_distance_to_water_2 : float) -> Vector3:
		var H := the_distance_to_water_0 + the_distance_to_water_1 + the_distance_to_water_2
		var center_of_pressure := ((the_distance_to_water_0 + H) * the_v0_world + (the_distance_to_water_1 + H) * the_v1_world + (the_distance_to_water_2 + H) * the_v2_world) / (4.0 * H)
		#ToDo: Formula generated by AI. Unsure if correct. To be tested.
		return center_of_pressure
	
	static func barycentric_interpolation(p0: Vector3, p1: Vector3, p2: Vector3, v0: float, v1: float, v2: float, p_res: Vector3) -> float:
		# Vectors from p0 to the other vertices and the target point
		var edge0 := p1 - p0
		var edge1 := p2 - p0
		var to_p  := p_res - p0
		
		# Dot products for the system of equations
		var d00 := edge0.dot(edge0)
		var d01 := edge0.dot(edge1)
		var d11 := edge1.dot(edge1)
		var d20 := to_p.dot(edge0)
		var d21 := to_p.dot(edge1)
		
		var denom := d00 * d11 - d01 * d01
		
		# Guard against division by zero (if the triangle is a line or a point)
		if is_zero_approx(denom):
			return v0
		
		# Compute the barycentric weights
		var weight1 := (d11 * d20 - d01 * d21) / denom
		var weight2 := (d00 * d21 - d01 * d20) / denom
		var weight0 := 1.0 - weight1 - weight2
		
		# Combine the vertex values based on weights
		return (weight0 * v0) + (weight1 * v1) + (weight2 * v2)
	
	static func create_from_triangle(triangle : MeshTriangle) -> BelowWaterTriangle:
		var the_geometric_center_world = 0.33333333 * (triangle.v0_world + triangle.v1_world + triangle.v2_world)
		var the_hydrostatic_center_world := calculate_hydrostatic_center_world(triangle.v0_world, triangle.v1_world, triangle.v2_world, triangle.distance_to_water_0, triangle.distance_to_water_1, triangle.distance_to_water_2)
		var hydrostatic_depth := barycentric_interpolation(triangle.v0_world, triangle.v1_world, triangle.v2_world, triangle.distance_to_water_0, triangle.distance_to_water_1, triangle.distance_to_water_2, the_hydrostatic_center_world)
		var the_area := triangle.area
		var the_static_pressure_force_world = fluid_density * gravitational_acceleration * hydrostatic_depth * the_area * triangle.normal_world
		
		return BelowWaterTriangle.new(triangle.v0_world, triangle.v1_world, triangle.v2_world, the_geometric_center_world, the_hydrostatic_center_world, the_static_pressure_force_world, the_area)
	
	static func create_from_points(the_v0_world: Vector3, the_v1_world: Vector3, the_v2_world : Vector3, the_distance_to_water_0 : float, the_distance_to_water_1 : float, the_distance_to_water_2 : float, normal_world: Vector3)  -> BelowWaterTriangle:
		var the_geometric_center_world = 0.33333333 * (the_v0_world + the_v1_world + the_v2_world)
		var the_hydrostatic_center_world = calculate_hydrostatic_center_world(the_v0_world, the_v1_world, the_v2_world, the_distance_to_water_0, the_distance_to_water_1, the_distance_to_water_2)
		var hydrostatic_depth := barycentric_interpolation(the_v0_world, the_v1_world, the_v2_world, the_distance_to_water_0, the_distance_to_water_1, the_distance_to_water_2, the_hydrostatic_center_world)
		var the_area = MeshTriangle.get_triangle_area_from_points(the_v0_world, the_v1_world, the_v2_world)
		var the_static_pressure_force_world = fluid_density * gravitational_acceleration * hydrostatic_depth * the_area * normal_world
		return BelowWaterTriangle.new(the_v0_world, the_v1_world, the_v2_world, the_geometric_center_world, the_hydrostatic_center_world, the_static_pressure_force_world, the_area)
	
	func world_drag_force(world_velocity : Vector3, drag_coefficient : float) -> Vector3:
		var velocity := world_velocity.length()
		var drag_force := -0.5 * area * drag_coefficient * fluid_density * velocity * world_velocity
		return drag_force
