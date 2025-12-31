extends Node

class_name InertiaCalculator

@export var linked_rigidbody: RigidBody3D
@export var box_collision_shape: CollisionShape3D

# Called when the node is added to the scene
func _ready():
	calculate_and_set_inertia()

# Method to perform the calculation and update the inertia property
func calculate_and_set_inertia():
	if not is_instance_valid(box_collision_shape):
		print("Error: CollisionShape3D node not found or invalid.")
		return

	var shape = box_collision_shape.shape
	if not shape is BoxShape3D:
		print("Error: CollisionShape3D does not contain a BoxShape3D.")
		return
	
	var box_shape := shape as BoxShape3D
	
	var size: Vector3 = box_shape.size
	var m: float = linked_rigidbody.mass # Use the mass set on the RigidBody

	# Calculate Moments of Inertia for a solid rectangular prism (box)
	# I = 1/12 * M * (side1^2 + side2^2)
	var ix: float = (1.0 / 12.0) * m * (size.y * size.y + size.z * size.z)
	var iy: float = (1.0 / 12.0) * m * (size.x * size.x + size.z * size.z)
	var iz: float = (1.0 / 12.0) * m * (size.x * size.x + size.y * size.y)
	
	# Set the custom inertia Vector3 (I_x, I_y, I_z)
	# Setting a custom inertia overrides Godot's automatic calculation.
	linked_rigidbody.inertia = Vector3(ix, iy, iz) 
	
	print("Inertia calculated and set to: ", linked_rigidbody.inertia)
