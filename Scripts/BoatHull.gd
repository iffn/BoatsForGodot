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

@export var linear_velocity_output : Label
@export var angular_velocity_output : Label
@export var buoyancy_force_output : Label
@export var drag_force_output : Label
@export var mass_output : Label

var mesh_triangles : Array[MeshTriangle]

func _ready() -> void:
	convert_mesh()

func _physics_process(delta: float) -> void:
	var start_time_usec: int = Time.get_ticks_usec()
	
	var triangles_below_water : Array[BelowWaterTriangle] = []
	
	for triangle in mesh_triangles:
		triangle.update_world_positions(hull_mesh.global_transform)
		assign(triangle, triangles_below_water)
	
	var velocity_world := rigidbody.linear_velocity
	
	var total_buoyancy := Vector3(0,0,0)
	var total_drag := Vector3(0,0,0)
	
	for triangle in triangles_below_water:
		# Buoyancy
		var application_position := triangle.hydrostatic_center_world - rigidbody.global_position
		var application_force := buoyancy_multiplier * triangle.static_pressure_force_world
		rigidbody.apply_force(application_force, application_position)
		
		var drag = drag_multiplier * triangle.world_drag_force(velocity_world, drag_coefficient)
		rigidbody.apply_force(drag)
		
		total_buoyancy += triangle.static_pressure_force_world
		total_drag += drag
	
	var end_time_usec: int = Time.get_ticks_usec()
	var elapsed_usec: int = end_time_usec - start_time_usec
	var elapsed_sec: float = float(elapsed_usec) / 1_000_000.0
	
	#print("Time taken: ", elapsed_sec, "s for ", triangles_below_water.size(), "/", mesh_triangles.size(), " triangles below water")
	
	if linear_velocity_output:
		linear_velocity_output.text = "Linear velocity: " + str(rigidbody.linear_velocity.length()).pad_decimals(2)
		#linear_velocity_output.text = "Linear velocity: " + str(rigidbody.global_transform.basis.inverse() * rigidbody.linear_velocity)
	if angular_velocity_output:
		angular_velocity_output.text = "Angular velocity: " + str(rigidbody.angular_velocity)
		#linear_velocity_output.text = "Linear velocity: " + str(rigidbody.global_transform.basis.inverse() * rigidbody.angular_velocity)
	if buoyancy_force_output:
		buoyancy_force_output.text = "Buoyancy: " + str(total_buoyancy.length()).pad_decimals(2)
	if drag_force_output:
		drag_force_output.text = "Drag: " + str(total_drag.length()).pad_decimals(2)
	if mass_output:
		mass_output.text = "Mass: " + str(rigidbody.mass)

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

func assign(triangle : MeshTriangle, below_water : Array[BelowWaterTriangle]) -> void:
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
		
		if v0.y > v1.y:
			if v0.y > v2.y:
				# Order tested
				high_point = v0
				low_point_1 = v1
				low_point_2 = v2
			else:
				# Order not tested
				high_point = v2
				low_point_1 = v0
				low_point_2 = v1
		else:
			if v1.y > v2.y:
				# Order tested
				high_point = v1
				low_point_1 = v2
				low_point_2 = v0
			else:
				# Order not tested
				high_point = v2
				low_point_1 = v0
				low_point_2 = v1
		
		var between_point_1 = lerp(high_point, low_point_1, high_point.y / (high_point.y - low_point_1.y))
		var between_point_2 = lerp(high_point, low_point_2, high_point.y / (high_point.y - low_point_2.y))
		
		below_water.append(BelowWaterTriangle.create_from_points(low_point_1, low_point_2, between_point_1, normal))
		below_water.append(BelowWaterTriangle.create_from_points(low_point_2, between_point_2, between_point_1, normal))
		#above_water.append(AboveWaterTriangle.new(between_point_1, between_point_2, high_point, normal))
		
	elif(above_water_counter == 2):
		var low_point : Vector3
		var high_point_1 : Vector3
		var high_point_2 : Vector3
		
		if v0.y < v1.y:
			if v0.y < v2.y:
				# Order tested
				low_point = v0
				high_point_1 = v1
				high_point_2 = v2
			else:
				# Order not tested
				low_point = v2
				high_point_1 = v0
				high_point_2 = v1
		else:
			if v1.y < v2.y:
				# Order tested
				low_point = v1
				high_point_1 = v2
				high_point_2 = v0
			else:
				# Order not tested
				low_point = v2
				high_point_1 = v0
				high_point_2 = v1
		
		#var between_point_1 = lerp(high_point_1, low_point, high_point_1.y / (high_point_1.y - low_point.y))
		var between_point_2 = lerp(high_point_2, low_point, high_point_2.y / (high_point_2.y - low_point.y))
		
		#above_water.append(Triangle.new(low_point, between_point_2, between_point_1, true, false, normal))
		#above_water.append(Triangle.new(between_point_1, between_point_2, high_point_1, true, false, normal))
		below_water.append(BelowWaterTriangle.create_from_points(between_point_2, high_point_2, high_point_1, normal))
		
	else:
		#above_water.append(self)
		pass


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
	var static_pressure_force_world : Vector3
	var geometric_center_world : Vector3
	var hydrostatic_center_world : Vector3
	var area : float
	static var fluid_density := 1000
	static var gravitational_acceleration := 9.81
	
	func _init(the_geometric_center_world : Vector3, the_hydrostatic_center_world : Vector3, the_static_pressure_force_world : Vector3, the_area : float):
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
		return center_of_pressure
	
	static func create_from_triangle(triangle : MeshTriangle) -> BelowWaterTriangle:
		var the_geometric_center_world = 0.33333333 * (triangle.v0_world + triangle.v1_world + triangle.v2_world)
		var the_hydrostatic_center_world = calculate_hydrostatic_center_world(triangle.v0_world, triangle.v1_world, triangle.v2_world)
		var the_area = triangle.area
		var the_static_pressure_force_world = fluid_density * gravitational_acceleration * BoatHull.get_distance_to_water(the_hydrostatic_center_world) * the_area * triangle.normal_world
		
		return BelowWaterTriangle.new(the_geometric_center_world, the_hydrostatic_center_world, the_static_pressure_force_world, the_area)
	
	static func create_from_points(v0_world: Vector3, v1_world: Vector3, v2_world, normal_world: Vector3)  -> BelowWaterTriangle:
		var the_geometric_center_world = 0.33333333 * (v0_world + v1_world + v2_world)
		var the_hydrostatic_center_world = calculate_hydrostatic_center_world(v0_world, v1_world, v2_world)
		var the_area = MeshTriangle.get_triangle_area_from_points(v0_world, v1_world, v2_world)
		var the_static_pressure_force_world = fluid_density * gravitational_acceleration * BoatHull.get_distance_to_water(the_hydrostatic_center_world) * the_area * normal_world
		return BelowWaterTriangle.new(the_geometric_center_world, the_hydrostatic_center_world, the_static_pressure_force_world, the_area)
	
	func world_drag_force(world_velocity : Vector3, drag_coefficient : float) -> Vector3:
		var velocity := world_velocity.length()
		var drag_force := -0.5 * area * drag_coefficient * fluid_density * velocity * world_velocity
		return drag_force
