tool

var li:Limage

func _init(l:Limage):
	li = l

func generate():
	# reload data
	var info_path = li.get_output_dir().plus_file(".%s.json" % li.get_fname())
	var f:File = File.new()
	if f.file_exists(info_path):
		if f.open(info_path, File.READ) == OK:
			var json = JSON.parse(f.get_as_text())
			if json.error == OK:
				f.close()
				li.data = json.result
				li.data.size = Vector2(li.data.size.x, li.data.size.y)
				_fix_points(li.data.root)
				li.on_all_layers(self, "_process_data")
				return
	push_error("couldn't load data %s" % info_path)

# convert the data to godot types
func _process_data(layer:Dictionary):
	if "texture" in layer:
		layer.texture_path = li.get_output_dir().plus_file(layer.texture)
	
	_fix_points(layer)
	
	layer.origin = Vector2(layer.origin.x, layer.origin.y)
	layer.position = Vector2(layer.position.x, layer.position.y)
	layer.area = Rect2(layer.area.x, layer.area.y, layer.area.w, layer.area.h)

func _fix_points(data:Dictionary):
	if "points" in data:
		for point in data.points:
			point.position = Vector2(point.position.x, point.position.y)
