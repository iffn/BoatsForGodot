extends Camera2D

class_name InspectorCamera

@export var zoom_speed := 0.05

var middle_mouse_button_pressed := false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			middle_mouse_button_pressed = event.pressed
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.0)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(-1.0)
	
	if event is InputEventMouseMotion:
		if middle_mouse_button_pressed:
			position -= event.relative

func _zoom(direction : float):
	var mouse_pos = get_local_mouse_position()
	var prev_zoom = zoom
	
	var zoom_offset := 1.0 + zoom_speed * direction
	zoom *= Vector2(zoom_offset, zoom_offset)
	
	var zoom_diff = prev_zoom - zoom
	position -= mouse_pos * zoom_diff / zoom
