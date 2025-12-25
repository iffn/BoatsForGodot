extends Control

class_name EasyChartPlot

@export var chart: Chart

@export var title := ""
@export var x_label := ""
@export var y_label := ""
@export var function_count := 1

# This Chart will plot 3 different functions
var functions: Array[Function]

var cp: ChartProperties = ChartProperties.new()

func _ready():
	# Let's create our @x values
	var x: Array[float] = [-180.0, 180.0]
	
	# And our y values. It can be an n-size array of arrays.
	# NOTE: `x.size() == y.size()` or `x.size() == y[n].size()`
	var y: Array[float] = [-10.0, 10.0]
	
	# Let's customize the chart properties, which specify how the chart
	# should look, plus some additional elements like labels, the scale, etc...
	cp = ChartProperties.new()
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.title = title
	cp.x_label = x_label
	cp.y_label = y_label
	cp.x_scale = 10
	cp.y_scale = 10
	cp.interactive = true 
	cp.show_legend = function_count > 1
	
	for i in range(function_count):
		var function := Function.new(
			x, y, "Initial data",
			{ 
				color = Color("ff0000ff"),
				marker = Function.Marker.CIRCLE,
				type = Function.Type.LINE,
				interpolation = Function.Interpolation.LINEAR
			}
		)
		functions.append(function)
	
	
	chart.plot(functions, cp)

func display_data(added_functions : Array[Function]):
	var max_x := 0.0
	var max_y := 0.0
	var min_x := 0.0
	var min_y := 0.0
	
	for i in range(functions.size()):
		var existing_function := functions[i]
		var added_function := added_functions[i]
		
		var x := added_function.__x
		var y := added_function.__y
		
		existing_function.__x.clear()
		existing_function.__x.append_array(x)
		
		existing_function.__y.clear()
		existing_function.__y.append_array(y)
		
		existing_function.name = added_function.name
		existing_function.props.set("color", added_function.get_color())
		
		max_x = max(max_x, max(x.max(), -x.min()))
		min_x = min(min_x, min(x.min(), x.max()))
		max_y = max(max_y, max(y.max(), -y.min()))
		min_y = min(min_y, min(y.min(), y.max()))
	
	if min_x < 0:
		max_x = max(max_x, -min_x)
		min_x = min(-max_x, min_x)
	if min_y < 0:
		max_y = max(max_y, -min_y)
		min_y = min(-max_y, min_y)
	
	chart.function_legend.clear()
	for function in added_functions:
		chart.function_legend.add_function(function)
	
	chart.set_x_domain(min_x, max_x)
	chart.set_y_domain(min_y, max_y)
	
	chart.queue_redraw()
