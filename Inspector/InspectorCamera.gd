extends Camera2D

class_name InspectorCamera

@export var zoom_speed := 0.05

var touches = {}
var last_pinch_distance = 0.0
var last_pinch_center = Vector2.ZERO
var middle_mouse_button_pressed := false

func _input(event: InputEvent) -> void:
	# --- MOUSE CONTROLS ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			middle_mouse_button_pressed = event.pressed
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_point(1.0 + zoom_speed, event.position)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_point(1.0 - zoom_speed, event.position)
	
	if event is InputEventMouseMotion and middle_mouse_button_pressed:
		position -= event.relative / zoom.x

	# --- MOBILE/TOUCH CONTROLS ---
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
		else:
			touches.erase(event.index)
			# Reset tracking when fingers lift
			if touches.size() < 2:
				last_pinch_distance = 0.0
				last_pinch_center = Vector2.ZERO

	if event is InputEventScreenDrag:
		touches[event.index] = event.position
		
		if touches.size() == 1:
			# Standard one-finger pan
			position -= event.relative / zoom.x
			
		elif touches.size() == 2:
			var touch_points = touches.values()
			var current_dist = touch_points[0].distance_to(touch_points[1])
			var current_center = (touch_points[0] + touch_points[1]) / 2.0
			
			# 1. Handle Panning (Moving while pinching)
			if last_pinch_center != Vector2.ZERO:
				var center_delta = current_center - last_pinch_center
				position -= center_delta / zoom.x
			
			# 2. Handle Zooming
			if last_pinch_distance > 0:
				var zoom_factor = current_dist / last_pinch_distance
				_zoom_at_point(zoom_factor, current_center)
			
			last_pinch_distance = current_dist
			last_pinch_center = current_center

func _zoom_at_point(factor: float, screen_point: Vector2):
	var prev_zoom = zoom
	zoom *= factor
	
	var pivot = get_viewport().get_canvas_transform().affine_inverse() * screen_point
	position += (pivot - position) * (1.0 - prev_zoom.x / zoom.x)
