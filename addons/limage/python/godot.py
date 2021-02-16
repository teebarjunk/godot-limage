TEMPLATE_TRES:str = """[gd_resource type="Resource" load_steps=2 format=2]

[ext_resource path="res://addons/limage/Limage.gd" type="Script" id=1]

[resource]
script = ExtResource( 1 )
data = """

def get_options(layer) -> str:
	options = []
	default = ""
	for child in layer:
		options.append(child.name)
		if child._old_visible:
			default = child.name
	default = '"' + default + '"'
	options = '"' + '", "'.join(options) + '"'
	return options, default

def get_var_name(layer):
	return "_".join(layer._full_path).replace(" ", "_").replace("-", "_").lower()

def get_path(layer):
	return '"'+ "/".join(layer._full_path) +'"'

def generate_script(all_layers) -> str:
	has_script:bool = False
	head = "tool\nextends LimageNode\n\n"
	tail = ""
	for layer in all_layers:
		if "options" in layer._tags:
			has_script = True
			o, d = get_options(layer)
			v = get_var_name(layer)
			n = get_path(layer)
			head += f"export(String, {o}) var _{v}:String = {d} setget set_{v}, get_{v}\n"
			tail += f"func get_{v}() -> String: return get_option({n})\n"
			tail += f"func set_{v}(v:String):\n\t_{v} = v\n\tset_option({n}, v)\n\n" # \n\tif _{v} != v and v != \"\":\n\t\t_{v} = v\n\t\t
		
		if "toggles" in layer._tags:
			has_script = True
			for child in layer:
				v = get_var_name(child)
				d = "true" if child._old_visible else "false"
				n = get_path(child)
				head += f"export(bool) var _{v}:bool = {d} setget set_{v}, get_{v}\n"
				tail += f"func get_{v}() -> bool: return get_toggle({n})\n"
				tail += f"func set_{v}(v:bool):\n\t_{v} = v\n\tset_toggle({n}, v)\n\n" # \n\tif _{v} != v:\n\t\t # \n\t\t_{v} = v
	
	return has_script, f"{head}\n{tail}"