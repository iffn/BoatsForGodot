extends Node

@export var boat_view : BoatView
var calculation_boat : BoatController:
	get:
		return boat_view.linked_boat

@export var _basic_geometry_name_holder: Control 
@export var _basic_geometry_output_holder: Control 

func evaluate_mesh():
	var names := _basic_geometry_name_holder.find_children("*", "Label")
	var output := _basic_geometry_output_holder.find_children("*", "Label")
	
	var mesh := calculation_boat.hull.hull_mesh.mesh

	var total_vertices = 0
	var surface_count = mesh.get_surface_count()

	for i in range(surface_count):
		var surface_arrays = mesh.surface_get_arrays(i)
		var vertices = surface_arrays[ArrayMesh.ARRAY_VERTEX]
		total_vertices += vertices.size() / 3  # Each vertex has 3 components (x, y, z)
	
	var buoyancy_multiplier = calculation_boat.hull.buoyancy_multiplier
	var drag_multiplier = calculation_boat.hull.drag_multiplier
	calculation_boat.hull.buoyancy_multiplier = 0.0
	calculation_boat.hull.drag_multiplier = 0.0
	var start_time_usec: int = Time.get_ticks_usec()
	calculation_boat.hull.apply_to_rigidbody()
	var end_time_usec: int = Time.get_ticks_usec()
	var elapsed_usec: int = end_time_usec - start_time_usec
	var elapsed_msec: float = float(elapsed_usec) / 1_000.0
	calculation_boat.hull.buoyancy_multiplier = buoyancy_multiplier
	calculation_boat.hull.drag_multiplier = drag_multiplier
	
	var data = calculation_boat.hull.calculate_all()
	
	var i = 0
	
	names[i].text = "Vertices"
	output[i].text = str(total_vertices)
	i+=1
	names[i].text = "Triangles"
	output[i].text = str(calculation_boat.hull.mesh_triangles.size())
	i+=1
	names[i].text = "Is closed"
	output[i].text = "Maybe"
	i+=1
	names[i].text = "Below water triangles"
	output[i].text = str(data.triangles_below_water.size())
	i+=1
	names[i].text = "Cut triangles"
	output[i].text = str(data.waterline_points.size() / 2)
	i+=1
	names[i].text = "Calculation time"
	output[i].text = str(elapsed_msec).pad_decimals(3)
	i+=1
