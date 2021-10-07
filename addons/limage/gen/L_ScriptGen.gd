tool

const SCRIPT_OPTION_HEAD:String = """
export(String, \"{options}\") var {name}:String = \"{default}\" setget set_{name}, get_{name}
"""

const SCRIPT_TOGGLE_HEAD:String = """
export(bool) var {name}:bool = {default} setget set_{name}, get_{name}
"""

const SCRIPT_OPTION_TAIL:String = """
func get_{name}() -> String: return _get_option(\"{path}")
func set_{name}(s:String):
	{name} = s
	_set_option(\"{path}", s)
"""

const SCRIPT_TOGGLE_TAIL:String = """
func get_{name}() -> bool: return _get_toggle(\"{path}")
func set_{name}(b:bool):
	{name} = b
	_set_toggle(\"{path}", b)
"""

const SCRIPT_OPTION_DEFAULT:String = """\tset_{name}(\"{default}\")"""
const SCRIPT_TOGGLE_DEFAULT:String = """\tset_{name}({default})"""


var li:Limage
var scenegen

var options = []
var toggles = []
var default = []

func _init(l:Limage):
	li = l
	scenegen = load("res://addons/limage/gen/L_SceneGen.gd").new(l)

#const TEMPLATE_OPTION = """"""
#const TEMPLATE_TOGGLE_HEAD = """"""
#const TEMPLATE_TOGGLE = """"

func generate():
	for d in li.data.root.layers:
		_script_layer(li, d)
	
	if options or toggles:
		
		var props = []
		props.append("func _get_property_list() -> Array:")
		props.append("\treturn [")
		
		var setter = []
		setter.append("func _set(property, value) -> bool:")
		setter.append("\tmatch property:")
		
		var getter = []
		getter.append("func _get(property):")
		getter.append("\tmatch property:")
		
		for item in options:
			props.append("\t\t{name=\"%s\",type=TYPE_STRING,hint=PROPERTY_HINT_ENUM,hint_string=\"%s\"}," % [item.varname, item.values])
			setter.append("\t\t\"%s\": _set_option(\"%s\", value)" % [item.varname, item.nodepath])
			getter.append("\t\t\"%s\": return _get_option(\"%s\")" % [item.varname, item.nodepath])
		
		for item in toggles:
			props.append("\t\t{name=\"%s\",type=TYPE_NIL,usage=PROPERTY_USAGE_GROUP,hint_string=\"%s_\"}," % [item.varname, item.varname])
			for t in item.toggles:
				props.append("\t\t{name=\"%s\",type=TYPE_BOOL}," % t.varname)
				setter.append("\t\t\"%s\": _set_toggle(\"%s\", value)" % [t.varname, t.nodepath])
				getter.append("\t\t\"%s\": return _get_toggle(\"%s\")" % [t.varname, t.nodepath])
		
		props.append("\t]")
		setter.append("\t\t_: return false")
		setter.append("\treturn true")
		
		var head = []
		head.append("tool")
		head.append("extends LimageNode")
		head.append("")
		head.append_array(getter)
		head.append("")
		head.append_array(setter)
		head.append("")
		head.append_array(props)
		
		var script = PoolStringArray(head).join("\n")
		
		var f:File = File.new()
		var path = li.get_output_dir().plus_file(li.get_fname() + ".gd")
		f.open(path, File.WRITE)
		f.store_string(script)
		f.close()

func replace_extension(s:String, ext:String) -> String:
	return s.rsplit(".", true, 1)[0] + ext

func _script_layer(li:Limage, data:Dictionary):
	if "options" in data.tags:
		var varname = get_path_as_var_name(data)
		var nodepath = get_path_as_node_path(data)
		var values = li.get_child_names(data).join(",")
		var default = get_default_child(data)
		options.append({varname=varname, nodepath=nodepath, default=default, values=values})
#		head_options.append(SCRIPT_OPTION_HEAD.strip_edges().format(props))
#		tail.append("")
#		tail.append(SCRIPT_OPTION_TAIL.strip_edges().format(props))
#		defaults.append(SCRIPT_OPTION_DEFAULT.format(props))
		
		# create sprite objects, to store offset data
		for child in data.layers:
			var sprite = scenegen.create_sprite(null, null, child)
			var packed = PackedScene.new()
			packed.pack(sprite)
			var path = li.get_scene_dir_path("options", child.texture.rsplit(".", true, 1)[0])
			ResourceSaver.save(path, packed)
	
	if "toggles" in data.tags:
		toggles.append({
			varname=get_path_as_var_name(data),
			toggles=[]
		})
		for child in data.layers:
			var varname = get_path_as_var_name(child)
			var nodepath = get_path_as_node_path(child)
			var default = "true" if child.visible else "false"
			toggles[-1].toggles.append({varname=varname, nodepath=nodepath, default=default})
#			head_toggles.append(SCRIPT_TOGGLE_HEAD.strip_edges().format(props))
#			tail.append("")
#			tail.append(SCRIPT_TOGGLE_TAIL.strip_edges().format(props))
#			defaults.append(SCRIPT_TOGGLE_DEFAULT.format(props))
			
			# create sprite objects, to store offset data
			var sprite = scenegen.create_sprite(null, null, child)
			var packed = PackedScene.new()
			packed.pack(sprite)
			var path = li.get_scene_dir_path("toggles", child.texture.rsplit(".", true, 1)[0])
			ResourceSaver.save(path, packed)
	
	if "layers" in data and data.layers:
		for d in data.layers:
			_script_layer(li, d)

func get_default_child(layer:Dictionary) -> String:
	var out = ""
	if "layers" in layer:
		for l in layer.layers:
			if l.visible:
				return l.name
			if not out:
				out = l.name
	return out

func get_path_as_node_path(layer:Dictionary) -> String:
	return PoolStringArray(layer.full_path).join("/")

func get_path_as_var_name(layer:Dictionary) -> String:
	var out = ""
	for c in PoolStringArray(layer.full_path).join("_").to_lower():
		if c in "abcdefghijklmnopqrstuvwxyz0123456789_":
			out += c
		else:
			out += "_"
	return out
