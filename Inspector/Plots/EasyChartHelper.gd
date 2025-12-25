class_name EaysChartHelper

static func get_default_chart_values() -> ChartProperties:
	var cp: ChartProperties = ChartProperties.new()
	
	cp = ChartProperties.new()
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.x_scale = 10
	cp.y_scale = 10
	cp.interactive = true 
	cp.show_legend = false
	
	return cp

static  func set_min_max(functions: Array[Function], chart: Chart):
	var max_x := 0.0
	var min_x := 0.0
	var max_y := 0.0
	var min_y := 0.0
	
	for function in functions:
		max_x = max(max_x, max(function.__x.max(), -function.__x.min()))
		min_x = min(min_x, min(function.__x.min(), function.__x.max()))
		max_y = max(max_y, max(function.__y.max(), -function.__y.min()))
		min_y = min(min_y, min(function.__y.min(), function.__y.max()))
	
	if min_x < 0:
		max_x = max(max_x, -min_x)
		min_x = min(-max_x, min_x)
	if min_y < 0:
		max_y = max(max_y, -min_y)
		min_y = min(-max_y, min_y)
	
	chart.set_x_domain(min_x, max_x)
	chart.set_y_domain(min_y, max_y)
