extends Node

class_name BoatHull

# Inspired by:
# https://www.gamedeveloper.com/programming/water-interaction-model-for-boats-in-video-games
# https://www.habrador.com/tutorials/unity-boat-tutorial
# https://github.com/iffn/iffnsBoatsForVRChat/blob/main/Scripts/HullCalculator.cs

# ToDo Debug:
# - Check assign functions if between points are calculated correctly -> Check mesh

@export var drag_coefficient : float = 0.05
@export var drag_multiplier : float  = 1.0
@export var buoyancy_multiplier : float  = 1.0
@export var hull_mesh: MeshInstance3D
@export var rigidbody: RigidBody3D

@export var linear_velocity_output : Label
@export var angular_velocity_output : Label
@export var buoyancy_force_output : Label
@export var drag_force_output : Label
@export var mass_output : Label

var mesh_triangles : Array[MeshTriangle]

var bounding_box : AABB:
	get:
		return hull_mesh.get_aabb()

func _ready() -> void:
	convert_mesh()

func _physics_process(delta: float) -> void:
	apply_to_rigidbody()

func apply_to_rigidbody():
	var triangles_below_water : Array[BelowWaterTriangle] = []
	
	for triangle in mesh_triangles:
		triangle.update_world_positions(hull_mesh.global_transform)
		assign_below_water(triangle, triangles_below_water)
	
	var velocity_world := rigidbody.linear_velocity
	
	for triangle in triangles_below_water:
		# Buoyancy
		#var application_position := triangle.geometric_center_world - rigidbody.global_position
		var application_position := triangle.hydrostatic_center_world - rigidbody.global_position
		var application_force := buoyancy_multiplier * triangle.static_pressure_force_world
		rigidbody.apply_force(application_force, application_position)
		
		var drag = drag_multiplier * triangle.world_drag_force(velocity_world, drag_coefficient)
		rigidbody.apply_force(drag)

func calculate_all() -> BoatCalculationData:
	var output := BoatCalculationData.new()
	var triangles_below_water : Array[BelowWaterTriangle] = []
	var waterline_points : Array[Vector3] = []
	
	for triangle in mesh_triangles:
		triangle.update_world_positions(hull_mesh.global_transform)
		assign_below_water(triangle, triangles_below_water)
		assign_water_line(triangle, waterline_points)
	
	var velocity_world := rigidbody.linear_velocity
	
	var water_x_max := -INF
	var water_x_min := INF
	var water_z_max := -INF
	var water_z_min := INF
	var water_y_min := INF
	
	for triangle in triangles_below_water:
		# Buoyancy
		var application_position := triangle.hydrostatic_center_world - rigidbody.global_position
		var application_force := buoyancy_multiplier * triangle.static_pressure_force_world
		
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

static func get_distance_to_water(world_position : Vector3) -> float:
	return world_position.y

func convert_mesh():
	mesh_triangles = []
	
	var mesh := hull_mesh.mesh
	var mesh_data_tool := MeshDataTool.new()
	mesh_data_tool.create_from_surface(mesh, 0)
	
	for face_index in range(mesh_data_tool.get_face_count()):
		var v0_index := mesh_data_tool.get_face_vertex(face_index, 0)
		var v1_index := mesh_data_tool.get_face_vertex(face_index, 1)
		var v2_index := mesh_data_tool.get_face_vertex(face_index, 2)
		
		var v0_position_local := mesh_data_tool.get_vertex(v0_index)
		var v1_position_local := mesh_data_tool.get_vertex(v1_index)
		var v2_position_local := mesh_data_tool.get_vertex(v2_index)
		
		var normal := mesh_data_tool.get_face_normal(face_index)
		var triangle := MeshTriangle.new(v0_position_local, v1_position_local, v2_position_local, normal)
		mesh_triangles.append(triangle)
	
	mesh_data_tool.clear()

func assign_water_line(triangle: MeshTriangle, water_line: Array[Vector3]) -> void:
	var v0 := triangle.v0_world
	var v1 := triangle.v1_world
	var v2 := triangle.v2_world
	
	var distance_to_water_0 := get_distance_to_water(v0)
	var distance_to_water_1 := get_distance_to_water(v1)
	var distance_to_water_2 := get_distance_to_water(v2)
	
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
	
	var distance_to_water_0 := get_distance_to_water(v0)
	var distance_to_water_1 := get_distance_to_water(v1)
	var distance_to_water_2 := get_distance_to_water(v2)
	
	var above_water_counter := 0
	
	if(distance_to_water_0 > 0): above_water_counter += 1
	if(distance_to_water_1 > 0): above_water_counter += 1
	if(distance_to_water_2 > 0): above_water_counter += 1
	
	if(above_water_counter == 0):
		below_water.append(BelowWaterTriangle.create_from_triangle(triangle))
	
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
		below_water.append(BelowWaterTriangle.create_from_points(low_point_1, low_point_2, between_point_1, normal))
		below_water.append(BelowWaterTriangle.create_from_points(low_point_2, between_point_2, between_point_1, normal))
		#above_water.append(AboveWaterTriangle.new(between_point_1, between_point_2, high_point, normal))
		
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
		
		#above_water.append(Triangle.new(low_point, between_point_2, between_point_1, true, false, normal))
		#above_water.append(Triangle.new(between_point_1, between_point_2, high_point_1, true, false, normal))
		below_water.append(BelowWaterTriangle.create_from_points(low_point, between_point_1, between_point_2, normal))
		
	else:
		#above_water.append(self)
		pass

func assign_underwater_mesh(mesh_instance : MeshInstance3D, triangles_below_water : Array[BelowWaterTriangle]):
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
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

class MeshTriangle:
	var v0_local : Vector3
	var v1_local : Vector3
	var v2_local : Vector3
	var normal_local : Vector3
	
	var v0_world : Vector3
	var v1_world : Vector3
	var v2_world : Vector3
	var normal_world : Vector3
	
	var area : float
	
	func _init(_v0_local: Vector3, _v1_local: Vector3, _v2_local: Vector3, _normal_local):
		v0_local = _v0_local
		v1_local = _v1_local
		v2_local = _v2_local
		normal_local = _normal_local
		area = get_triangle_area_from_points(v0_local, v1_local, v2_local)
	
	func update_world_positions(global_transform: Transform3D):
		v0_world = global_transform * v0_local
		v1_world = global_transform * v1_local
		v2_world = global_transform * v2_local
		normal_world = (global_transform.basis * normal_local).normalized()
	
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
	
	static func calculate_hydrostatic_center_world(v0_world: Vector3, v1_world: Vector3, v2_world: Vector3) -> Vector3:
		var h0 := BoatHull.get_distance_to_water(v0_world)
		var h1 := BoatHull.get_distance_to_water(v1_world)
		var h2 := BoatHull.get_distance_to_water(v2_world)
		var H := h0 + h1 + h2
		var center_of_pressure := ((h0 + H) * v0_world + (h1 + H) * v1_world + (h2 + H) * v2_world) / (4.0 * H)
		#ToDo: Formula generated by AI. Unsure if correct. To be tested.
		return center_of_pressure
	
	static func create_from_triangle(triangle : MeshTriangle) -> BelowWaterTriangle:
		var the_geometric_center_world = 0.33333333 * (triangle.v0_world + triangle.v1_world + triangle.v2_world)
		var the_hydrostatic_center_world = calculate_hydrostatic_center_world(triangle.v0_world, triangle.v1_world, triangle.v2_world)
		var the_area = triangle.area
		var the_static_pressure_force_world = fluid_density * gravitational_acceleration * BoatHull.get_distance_to_water(the_hydrostatic_center_world) * the_area * triangle.normal_world
		
		return BelowWaterTriangle.new(triangle.v0_world, triangle.v1_world, triangle.v2_world, the_geometric_center_world, the_hydrostatic_center_world, the_static_pressure_force_world, the_area)
	
	static func create_from_points(v0_world: Vector3, v1_world: Vector3, v2_world, normal_world: Vector3)  -> BelowWaterTriangle:
		var the_geometric_center_world = 0.33333333 * (v0_world + v1_world + v2_world)
		var the_hydrostatic_center_world = calculate_hydrostatic_center_world(v0_world, v1_world, v2_world)
		var the_area = MeshTriangle.get_triangle_area_from_points(v0_world, v1_world, v2_world)
		var the_static_pressure_force_world = fluid_density * gravitational_acceleration * BoatHull.get_distance_to_water(the_hydrostatic_center_world) * the_area * normal_world
		return BelowWaterTriangle.new(v0_world, v1_world, v2_world, the_geometric_center_world, the_hydrostatic_center_world, the_static_pressure_force_world, the_area)
	
	func world_drag_force(world_velocity : Vector3, drag_coefficient : float) -> Vector3:
		var velocity := world_velocity.length()
		var drag_force := -0.5 * area * drag_coefficient * fluid_density * velocity * world_velocity
		return drag_force
