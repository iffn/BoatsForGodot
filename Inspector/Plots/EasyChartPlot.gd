extends Control

class_name EasyChartPlot

@export var chart: Chart

@export var title := ""
@export var x_label := ""
@export var y_label := ""

# This Chart will plot 3 different functions
var f1: Function

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
	
	f1 = Function.new(
		x, y, "Initial data",
		{ 
			color = Color("ff0000ff"),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		}
	)
	
	chart.plot([f1], cp)

func display_data(x : Array[float], y : Array[float], the_title : String):
	f1.__x.clear()
	f1.__x.append_array(x)
	
	f1.__y.clear()
	f1.__y.append_array(y)
	
	f1.name = the_title
	
	if(x.min() < 0.0):
		var max_x : float = max(x.max(), -x.min())
		chart.set_x_domain(-max_x, max_x)
	else:
		chart.set_x_domain(0.0, x.max())
	
	if(y.min() < 0.0):
		var max_y : float = max(y.max(), -y.min())
		chart.set_y_domain(-max_y, max_y)
	else:
		chart.set_y_domain(0.0, y.max())
	
	chart.queue_redraw()
