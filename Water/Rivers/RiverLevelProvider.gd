extends WaterLevelProvider

@export var heightmap : Texture2D
@export var grid_size : float
@export var max_height : float

var img : Image

func _ready() -> void:
	img = heightmap.get_image()
	if img.is_compressed():
		img.decompress()

func get_distance_to_water(world_position : Vector3) -> float:
	var pos := Vector2(world_position.x, world_position.z)
	var half_size := grid_size * 0.5
	
	var uv_x : float = inverse_lerp(-half_size, half_size, pos.x)
	var uv_y : float = inverse_lerp(-half_size, half_size, pos.y)

	var UV := Vector2(uv_x, uv_y)
	
	var tex_size := img.get_size()
	var pixel_x := int(UV.x * (tex_size.x - 1))
	var pixel_y := int(UV.y * (tex_size.y - 1))
	
	pixel_x = clampi(pixel_x, 0, tex_size.x - 1)
	pixel_y = clampi(pixel_y, 0, tex_size.y - 1)
	
	var height := img.get_pixel(pixel_x, pixel_y).r
	
	return world_position.y - height * max_height
