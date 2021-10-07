tool

var li:Limage

func _init(l:Limage):
	li = l

func generate():
	var file_path = li.file_path
	var output = ProjectSettings.globalize_path(li.get_output_dir())
	var path = ProjectSettings.globalize_path(file_path) if file_path.begins_with("res://") else file_path
	var args = [path,
		"--output", output,
		"--format", li.format,
		"--scale", li.scale,
		"--padding", li.padding,
		"--quant", PoolStringArray([1 if li.quantize_enabled else 0, li.quantize_method, li.quantize_colors]).join(","),
		"--seperator", li.seperator,
		"--origin", "%s,%s" % [li.origin.x, li.origin.y]
	]
	
	if li.debug_print: args.append("--print")
	if li.debug_skip_images: args.append("--skip_images")
	var out:Array = []
	var _a = OS.execute("limage", args, true, out, true)
	for line in out:
		for l in line.split("\n"):
			if l.strip_edges():
				print("\t> ", l)
	
