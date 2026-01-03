extends Node

class_name BoatHull

# Inspired by:
# https://www.gamedeveloper.com/programming/water-interaction-model-for-boats-in-video-games
# https://www.habrador.com/tutorials/unity-boat-tutorial
# https://github.com/iffn/iffnsBoatsForVRChat/blob/main/Scripts/HullCalculator.cs

var drag_coefficient : float = 0.05
var drag_multiplier : float  = 1.0
var buoyancy_multiplier : float  = 1.0

var hull_mesh: MeshInstance3D
var rigidbody: RigidBody3D
var water_level: WaterLevelProvider

var mesh_vertices_local : Array[Vector3]
var mesh_triangles : Array[MeshTriangle]
var mesh_vertices_world : Array[Vector3]
var distances_to_water : Array[float]

const KINEMATIC_VISCOSITY_WATER : float = 1000034.0;

const INV_LN10 = 0.43429448190325
static func log_10(value : float) -> float:
	return log(value) * INV_LN10

var bounding_box : AABB:
	get:
		return hull_mesh.get_aabb()

func setup(the_hull_mesh: MeshInstance3D, the_rigidbody: RigidBody3D, the_water_level: WaterLevelProvider):
	hull_mesh = the_hull_mesh
	rigidbody = the_rigidbody
	water_level = the_water_level
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
		mesh_vertices_world[i] = hull_transform * mesh_vertices_local[i]
		distances_to_water[i] = water_level.get_distance_to_water(mesh_vertices_world[i])
		
	for triangle in mesh_triangles:
		triangle.normal_world = (hull_transform.basis * triangle.normal_local).normalized()

func calculate_velocity_at_point(point_global : Vector3, center_of_mass : Vector3, linear_velocity : Vector3, angular_velocity : Vector3) -> Vector3:
	var r = point_global - center_of_mass
	return linear_velocity + angular_velocity.cross(r)

func apply_to_rigidbody():
	var triangles_below_water : Array[BelowWaterTriangle] = []
	
	update_mesh_positions()
	
	for triangle in mesh_triangles:
		assign_below_water(triangle, triangles_below_water)
	
	var velocity_world := rigidbody.linear_velocity
	var boat_length = bounding_box.size.z
	var reynolds_number = velocity_world.length() * boat_length / KINEMATIC_VISCOSITY_WATER;
	var friction_coefficient_divider_part : float = (BoatHull.log_10(reynolds_number) - 2.0)
	var frictional_drag_coefficient := 0.075 / (friction_coefficient_divider_part * friction_coefficient_divider_part)
	
	var center_of_mass := rigidbody.global_transform * rigidbody.center_of_mass
	
	for triangle in triangles_below_water:
		triangle.calculate_point_velocities(center_of_mass, velocity_world, rigidbody.angular_velocity)
		
		triangle.calculate_all(velocity_world, frictional_drag_coefficient)
		# Buoyancy
		#var application_position := triangle.geometric_center_world - rigidbody.global_position
		var hydrostatic_center_application := triangle.hydrostatic_center_world - rigidbody.global_position
		var buoyancy_application := buoyancy_multiplier * triangle.static_pressure_force_world
		buoyancy_application.x = 0.0
		buoyancy_application.z = 0.0
		rigidbody.apply_force(buoyancy_application, hydrostatic_center_application)
		
		rigidbody.apply_force(drag_multiplier * triangle.f0_friction_drag, triangle.p0_world - rigidbody.global_position)
		rigidbody.apply_force(drag_multiplier * triangle.f0_pressure_drag, triangle.p0_world - rigidbody.global_position)
		rigidbody.apply_force(drag_multiplier * triangle.f1_friction_drag, triangle.p1_world - rigidbody.global_position)
		rigidbody.apply_force(drag_multiplier * triangle.f1_pressure_drag, triangle.p1_world - rigidbody.global_position)
		rigidbody.apply_force(drag_multiplier * triangle.f2_friction_drag, triangle.p2_world - rigidbody.global_position)
		rigidbody.apply_force(drag_multiplier * triangle.f2_pressure_drag, triangle.p2_world - rigidbody.global_position)

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
	
	var boat_length = bounding_box.size.z
	var reynolds_number = velocity_world.length() * boat_length / KINEMATIC_VISCOSITY_WATER;
	var friction_coefficient_divider_part : float = (BoatHull.log_10(reynolds_number) - 2.0)
	var frictional_drag_coefficient := 0.075 / (friction_coefficient_divider_part * friction_coefficient_divider_part)
	
	var area := 0.0
	var friction_drag_force := Vector3(0,0,0)
	var pressure_drag_force := Vector3(0,0,0)
	
	var center_of_mass := rigidbody.global_transform * rigidbody.center_of_mass
	var buoyancy_torque := Vector3(0,0,0)
	var friction_drag_torque := Vector3(0,0,0)
	var pressure_drag_torque := Vector3(0,0,0)
	
	for triangle in triangles_below_water:
		triangle.calculate_point_velocities(center_of_mass, velocity_world, rigidbody.angular_velocity)
		triangle.calculate_all(velocity_world, frictional_drag_coefficient)
		
		var a := triangle.p0_world - water_line_point;
		var b := triangle.p1_world - water_line_point;
		var c := triangle.p2_world - water_line_point;
		
		var tetrahedron_volume := (-0.1666666667) * a.dot(b.cross(c));
		var tetrahedron_center := 0.25 * (triangle.p0_world + triangle.p1_world + triangle.p2_world + water_line_point)
		
		displaced_volume_additive += tetrahedron_volume
		center_of_buoyancy_world_additive += tetrahedron_volume * tetrahedron_center	
		
		output.buoyancy_force += triangle.static_pressure_force_world
		water_y_min = min(triangle.v0_world.y, water_y_min)
		water_y_min = min(triangle.v1_world.y, water_y_min)
		water_y_min = min(triangle.v2_world.y, water_y_min)
		
		area += triangle.area
		friction_drag_force += triangle.f0_friction_drag
		pressure_drag_force += triangle.f0_pressure_drag
		friction_drag_force += triangle.f1_friction_drag
		pressure_drag_force += triangle.f1_pressure_drag
		friction_drag_force += triangle.f2_friction_drag
		pressure_drag_force += triangle.f2_pressure_drag
		
		var center_of_mass_world := rigidbody.global_transform * rigidbody.center_of_mass
		var lever_arm_hydrostatic_center := triangle.hydrostatic_center_world - center_of_mass_world
		
		buoyancy_torque += (lever_arm_hydrostatic_center).cross(Vector3(0, triangle.static_pressure_force_world.y, 0))
		
		friction_drag_torque += (triangle.p0_world - center_of_mass_world).cross(triangle.f0_friction_drag)
		pressure_drag_torque += (triangle.p0_world - center_of_mass_world).cross(triangle.f0_pressure_drag)
		friction_drag_torque += (triangle.p1_world - center_of_mass_world).cross(triangle.f1_friction_drag)
		pressure_drag_torque += (triangle.p1_world - center_of_mass_world).cross(triangle.f1_pressure_drag)
		friction_drag_torque += (triangle.p2_world - center_of_mass_world).cross(triangle.f2_friction_drag)
		pressure_drag_torque += (triangle.p2_world - center_of_mass_world).cross(triangle.f2_pressure_drag)
	
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
		output.friction_drag_force = friction_drag_force
		output.pressure_drag_force = pressure_drag_force
		output.buoyancy_torque = buoyancy_torque
		output.friction_drag_torque = friction_drag_force
		output.pressure_drag_torque = pressure_drag_torque
		
	
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
	var p0 := triangle.p0_world
	var p1 := triangle.p1_world
	var p2 := triangle.p2_world
	
	var distance_to_water_0 := water_level.get_distance_to_water(p0)
	var distance_to_water_1 := water_level.get_distance_to_water(p1)
	var distance_to_water_2 := water_level.get_distance_to_water(p2)
	
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
		
		if p0.y > p1.y:
			if p0.y > p2.y:
				# Order tested
				high_point = p0
				low_point_1 = p1
				low_point_2 = p2
				distance_to_water_high = distance_to_water_0
				distance_to_water_low_1 = distance_to_water_1
				distance_to_water_low_2 = distance_to_water_2
			else:
				# Order not tested
				high_point = p2
				low_point_1 = p0
				low_point_2 = p1
				distance_to_water_high = distance_to_water_2
				distance_to_water_low_1 = distance_to_water_0
				distance_to_water_low_2 = distance_to_water_1
		else:
			if p1.y > p2.y:
				# Order tested
				high_point = p1
				low_point_1 = p2
				low_point_2 = p0
				distance_to_water_high = distance_to_water_1
				distance_to_water_low_1 = distance_to_water_2
				distance_to_water_low_2 = distance_to_water_0
			else:
				# Order not tested
				high_point = p2
				low_point_1 = p0
				low_point_2 = p1
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
		
		if p0.y < p1.y:
			if p0.y < p2.y:
				# Order tested
				low_point = p0
				high_point_1 = p1
				high_point_2 = p2
				distance_to_water_low = distance_to_water_0
				distance_to_water_high_1 = distance_to_water_1
				distance_to_water_high_2 = distance_to_water_2
			else:
				# Order not tested
				low_point = p2
				high_point_1 = p0
				high_point_2 = p1
				distance_to_water_low = distance_to_water_2
				distance_to_water_high_1 = distance_to_water_0
				distance_to_water_high_2 = distance_to_water_1
		else:
			if p1.y < p2.y:
				# Order tested
				low_point = p1
				high_point_1 = p2
				high_point_2 = p0
				distance_to_water_low = distance_to_water_1
				distance_to_water_high_1 = distance_to_water_2
				distance_to_water_high_2 = distance_to_water_0
			else:
				# Order not tested
				low_point = p2
				high_point_1 = p0
				high_point_2 = p1
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
	var p0 := triangle.p0_world
	var p1 := triangle.p1_world
	var p2 := triangle.p2_world
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
				high_point = p0
				low_point_1 = p1
				low_point_2 = p2
				h_high = h0
				h_low_1 = h1
				h_low_2 = h2
			else:
				# Order not tested
				high_point = p2
				low_point_1 = p0
				low_point_2 = p1
				h_high = h2
				h_low_1 = h0
				h_low_2 = h1
		else:
			if h1 > h2:
				# Order tested
				high_point = p1
				low_point_1 = p2
				low_point_2 = p0
				h_high = h1
				h_low_1 = h2
				h_low_2 = h0
			else:
				# Order not tested
				high_point = p2
				low_point_1 = p0
				low_point_2 = p1
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
				low_point = p0
				high_point_1 = p1
				high_point_2 = p2
				h_low = h0
				h_high_1 = h1
				h_high_2 = h2
			else:
				# Order not tested
				low_point = p2
				high_point_1 = p0
				high_point_2 = p1
				h_low = h2
				h_high_1 = h0
				h_high_2 = h1
		else:
			if h1 < h2:
				# Order tested
				low_point = p1
				high_point_1 = p2
				high_point_2 = p0
				h_low = h1
				h_high_1 = h2
				h_high_2 = h0
			else:
				# Order not tested
				low_point = p2
				high_point_1 = p0
				high_point_2 = p1
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
	
	for triangle in triangles_below_water:
		surface_tool.add_vertex(triangle.p0_world)
		surface_tool.add_vertex(triangle.p1_world)
		surface_tool.add_vertex(triangle.p2_world)
	
	for triangle in mesh_triangles:
		break
		surface_tool.add_vertex(triangle.p0_world)
		surface_tool.add_vertex(triangle.p1_world)
		surface_tool.add_vertex(triangle.p2_world)
	
	surface_tool.generate_normals()
	
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
	var f_fully_submerged := data.all_forces.y - buoyancy_goal
	if print_status:
		print("Fully submerged (x = ", x_fully_submerged, "): buoyancy_force = ", data.all_forces.y, ", error = ", f_fully_submerged)

	# Evaluate above water
	rigidbody.position.y = x_above_water
	data = calculate_all()
	var f_above_water := data.all_forces.y - buoyancy_goal
	if print_status:
		print("Above water (x = ", x_above_water, "): buoyancy_force = ", data.all_forces.y, ", error = ", f_above_water)

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
		var f1 := data.all_forces.y - buoyancy_goal
		if print_status:
			print("Iteration ", i, ": Tried x = ", x2, ", buoyancy_force = ", data.all_forces.y, ", error = ", f1)

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
	var water_plane_size_XZ: Vector2
	var draft: float
	var triangles_below_water : Array[BelowWaterTriangle]
	var waterline_points : Array[Vector3]
	var center_of_buoyancy_world: Vector3
	var displaced_volume: float
	var friction_drag_force: Vector3
	var pressure_drag_force: Vector3
	
	var buoyancy_torque : Vector3
	var friction_drag_torque: Vector3
	var pressure_drag_torque: Vector3
	
	var all_forces : Vector3:
		get:
			return buoyancy_force + friction_drag_force + pressure_drag_force
	
	var all_torques : Vector3:
		get:
			return buoyancy_torque + friction_drag_torque + pressure_drag_torque

class MeshTriangle:
	var i0 : int
	var i1 : int
	var i2 : int
	
	var mesh_vertices_local : Array[Vector3]
	var mesh_vertices_world : Array[Vector3]
	var distances_to_water : Array[float]
	
	var p0_local : Vector3:
		get:
			return mesh_vertices_local[i0]
	var p1_local : Vector3:
		get:
			return mesh_vertices_local[i1]
	var p2_local : Vector3:
		get:
			return mesh_vertices_local[i2]
	
	var p0_world : Vector3:
		get:
			return mesh_vertices_world[i0]
	var p1_world : Vector3:
		get:
			return mesh_vertices_world[i1]
	var p2_world : Vector3:
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
		area = get_triangle_area_times_normal_from_points(p0_local, p1_local, p2_local).length()
	
	static func get_triangle_area_times_normal_from_points(A: Vector3, B: Vector3, C: Vector3) -> Vector3:
		var ab := B - A
		var ac := C - A
		return 0.5 * ac.cross(ab)

class BelowWaterTriangle:
	var p0_world : Vector3
	var p1_world : Vector3
	var p2_world : Vector3
	var v0_world : Vector3
	var v1_world : Vector3
	var v2_world : Vector3
	var distance_to_water_0 : float
	var distance_to_water_1 : float
	var distance_to_water_2 : float
	var area : float
	var normal_world : Vector3
	
	var hydrostatic_center_world : Vector3
	var hydrostatic_depth : float
	var static_pressure_force_world : Vector3
	
	var geometric_center_world : Vector3
	
	var f0_friction_drag : Vector3
	var f1_friction_drag : Vector3
	var f2_friction_drag : Vector3
	
	var f0_pressure_drag : Vector3
	var f1_pressure_drag : Vector3
	var f2_pressure_drag : Vector3
	
	static var WATER_DENSITY := 1000
	static var GRAVITATIONAL_ACCELERATION := 9.81
	
	static var PRESSURE_DRAG_COEFFICIENT := 0.5
	static var SUCTION_DRAG_COEFFICIENT := 0.05
	
	func _init(the_p0_world: Vector3, the_p1_world: Vector3, the_p2_world, the_distance_to_water_0 : float, the_distance_to_water_1 : float, the_distance_to_water_2 : float, the_area : float, the_normal_world : Vector3):
		p0_world = the_p0_world
		p1_world = the_p1_world
		p2_world = the_p2_world
		distance_to_water_0 = the_distance_to_water_0
		distance_to_water_1 = the_distance_to_water_1
		distance_to_water_2 = the_distance_to_water_2
		area = the_area
		normal_world = the_normal_world
	
	static func create_from_triangle(triangle : MeshTriangle) -> BelowWaterTriangle:
		return BelowWaterTriangle.new(triangle.p0_world, triangle.p1_world, triangle.p2_world, triangle.distance_to_water_0, triangle.distance_to_water_1, triangle.distance_to_water_2, triangle.area, triangle.normal_world)
	
	static func create_from_points(the_p0_world: Vector3, the_p1_world: Vector3, the_p2_world : Vector3, the_distance_to_water_0 : float, the_distance_to_water_1 : float, the_distance_to_water_2 : float, the_normal_world: Vector3)  -> BelowWaterTriangle:
		var the_area = MeshTriangle.get_triangle_area_times_normal_from_points(the_p0_world, the_p1_world, the_p2_world).length()
		return BelowWaterTriangle.new(the_p0_world, the_p1_world, the_p2_world, the_distance_to_water_0, the_distance_to_water_1, the_distance_to_water_2, the_area, the_normal_world)
	
	func calculate_point_velocities(center_of_mass : Vector3, linear_velocity : Vector3, angular_velocity : Vector3):
		v0_world = linear_velocity + angular_velocity.cross(p0_world - center_of_mass)
		v1_world = linear_velocity + angular_velocity.cross(p1_world - center_of_mass)
		v2_world = linear_velocity + angular_velocity.cross(p2_world - center_of_mass)
	
	func calculate_all(world_linear_velocity : Vector3, frictional_drag_coefficient):
		geometric_center_world = 0.33333333 * (p0_world + p1_world + p2_world)
		hydrostatic_center_world = calculate_hydrostatic_center_world(p0_world, p1_world, p2_world, distance_to_water_0, distance_to_water_1, distance_to_water_2)
		hydrostatic_depth = barycentric_interpolation(p0_world, p1_world, p2_world, distance_to_water_0, distance_to_water_1, distance_to_water_2, hydrostatic_center_world)
		static_pressure_force_world = WATER_DENSITY * GRAVITATIONAL_ACCELERATION * hydrostatic_depth * area * normal_world
		
		var thrid_area = area * 0.333333333
		
		var v0_normal_magnitude := v0_world.dot(normal_world)
		var v0_normal := v0_normal_magnitude * normal_world
		var v0_tangential := v0_world - v0_normal
		f0_friction_drag = -0.5 * WATER_DENSITY * thrid_area * frictional_drag_coefficient * v0_tangential.length() * v0_tangential
		var v0_cp = PRESSURE_DRAG_COEFFICIENT if v0_normal_magnitude > 0 else SUCTION_DRAG_COEFFICIENT
		f0_pressure_drag = -0.5 * WATER_DENSITY * thrid_area * v0_cp * v0_normal_magnitude * abs(v0_normal_magnitude) * normal_world
		
		var v1_normal_magnitude := v1_world.dot(normal_world)
		var v1_normal := v1_normal_magnitude * normal_world
		var v1_tangential := v1_world - v1_normal
		f1_friction_drag = -0.5 * WATER_DENSITY * thrid_area * frictional_drag_coefficient * v1_tangential.length() * v1_tangential
		var v1_cp = PRESSURE_DRAG_COEFFICIENT if v1_normal_magnitude > 0 else SUCTION_DRAG_COEFFICIENT
		f1_pressure_drag = -0.5 * WATER_DENSITY * thrid_area * v1_cp * v1_normal_magnitude * abs(v1_normal_magnitude) * normal_world
		
		var v2_normal_magnitude := v2_world.dot(normal_world)
		var v2_normal := v2_normal_magnitude * normal_world
		var v2_tangential := v2_world - v2_normal
		f2_friction_drag = -0.5 * WATER_DENSITY * thrid_area * frictional_drag_coefficient * v2_tangential.length() * v2_tangential
		var v2_cp = PRESSURE_DRAG_COEFFICIENT if v2_normal_magnitude > 0 else SUCTION_DRAG_COEFFICIENT
		f2_pressure_drag = -0.5 * WATER_DENSITY * thrid_area * v2_cp * v2_normal_magnitude * abs(v2_normal_magnitude) * normal_world
	
	static func calculate_hydrostatic_center_world(the_p0_world: Vector3, the_p1_world: Vector3, the_p2_world: Vector3, the_distance_to_water_0 : float, the_distance_to_water_1 : float, the_distance_to_water_2 : float) -> Vector3:
		var H := the_distance_to_water_0 + the_distance_to_water_1 + the_distance_to_water_2
		var center_of_pressure := ((the_distance_to_water_0 + H) * the_p0_world + (the_distance_to_water_1 + H) * the_p1_world + (the_distance_to_water_2 + H) * the_p2_world) / (4.0 * H)
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
