tool
extends Resource
class_name Limage

export(Dictionary) var data:Dictionary # everything is stored in a dict, so trans to json is easier.

var name:String setget, get_name
var size:Vector2 setget, get_size
var layers:Array setget, get_layers

func get_name() -> String: return data.name
func get_size() -> Vector2: return _v(data.size)
func get_layers(l:Dictionary=data): return l.get("layers", [])

func get_varname(d:Dictionary=data) -> String:
	return PoolStringArray(d.path).join("_").replace(" ", "_").replace("-", "_")

func get_layer(n:String, d:Dictionary=data):
	for part in n.split("/"):
		d = _get_layer(d, part)
		if d == null:
			print("LIMAGE: couldn't find %s in %s" % [part, n])
			return null
	return d

func _get_layer(d:Dictionary, n:String):
	for l in d.layers:
		if l.name == n:
			return l
	return null

func all_layers_with_tag(tag:String, d:Dictionary=data) -> Array:
	var layers = all_layers(d)
	for i in range(len(layers)-1, -1, -1):
		if not tag in layers[i].tags:
			layers.remove(i)
	return layers

func all_layers(d:Dictionary=data) -> Array:
	return _all_layers(d, [])

func _all_layers(layer, out:Array):
	out.append(layer)
	if "layers" in layer:
		for child in layer.layers:
			_all_layers(child, out)
	return out

func set_layer_as_cursor(name:String):
	var layer = get_layer(name)
	if layer:
		if "texture" in layer:
			var tex = load(layer.texture)
			var origin = -_v(layer.origin)
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, origin)
		else:
			prints(layer.name, "has no texture")
	else:
		prints("no layer ", name)

func get_node_type(layer:Dictionary, _as_controls:bool):
	var node:Node
	if "texture" in layer:
		node = (TextureRect if _as_controls else Sprite).new()
	else:
		node = (Control if _as_controls else Node2D).new()
	
	if _as_controls:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if "options" in layer.tags:
		node.set_script(load("res://addons/limage/LimageOption.gd"))
	elif "button" in layer.tags:
		node.set_script(load("res://addons/limage/LimageButton.gd"))
	
	return node

#	if "options" in layer.tags:
#		return load("res://addons/limage/LimageOption.gd")
#	elif "button" in layer.tags:
#		return load("res://addons/limage/LimageButton.gd")
#	elif "texture" in layer:
#		return TextureRect if _as_controls else Sprite
#	else:
#		return Control if _as_controls else Node2D

func get_layer_names(l:Dictionary=data) -> PoolStringArray:
	var out = []
	var layers = get_layers()
	for l in layers:
		out.append(l.name)
	return PoolStringArray(out)

func apply_name(n:Node, l:Dictionary=data):
	n.name = l.get("name", n.name)

func apply_visible(n:Node, l:Dictionary=data):
	if "visible" in n:
		n.visible = l.visible

func apply_opacity(n:Node, l:Dictionary=data):
	if "opacity" in n: # Sprite3D
		n.opacity = l.opacity / 255.0
	elif "modulate" in n: # Sprite2D, TextureRect
		n.modulate.a = l.opacity / 255.0

func apply_blend_mode(n:Node, l:Dictionary=data):
	if "blend_mode" in n:
		n.blend_mode = l.blend_mode

func apply_texture(n:Node, d:Dictionary=data):
	if "texture" in n and "texture" in d:
		n.texture = load(d.texture)
		if "centered" in n:
			n.centered = false
		
#		elif "rect_pivot_offset" in n:
#			n.rect_pivot_offset = -_v(d.origin)

func apply_position(n:Node, d:Dictionary=data):
	if "global_position" in n:
		n.global_position = _v(d.global_position)
		if "offset" in n:
			n.offset = _v(d.origin)
	elif "rect_global_position" in n:
		n.rect_global_position = _v(d.global_position) + _v(d.origin)
		n.rect_pivot_offset = -_v(d.origin)
	else:
		prints("couldn't set position", n, d.name)

func update_scene(parent_scene:Node, _as_controls:bool=false, _print:bool=true):
	update_node(parent_scene, parent_scene, data, 0, _as_controls, _print)

func update_node(parent_scene:Node, node:Node, info:Dictionary, depth:int=0, _as_controls:bool=false, _print:bool=true):
	apply_name(node, info)
	
	if "layer_info" in node:
		node.layer_info = info
	
	if _print:
		var print_head = "\t".repeat(depth)
		print(print_head, node.name)
	
	apply_visible(node, info)
	apply_opacity(node, info)
	
	if "options" in info.tags:
		var default = get_default_layer(info)
		node.option = default.name
		apply_texture(node, default)
		apply_position(node, default)
	
	else:
		# update settings
		if node != parent_scene:
			apply_position(node, info)
			apply_texture(node, info)
		
		# create and/or update child layers
		if "layers" in info:
			for child_info in info.layers:
				var child = node.get_node_or_null(child_info.name)
				# create new
				if child == null:
					child = get_node_type(child_info, _as_controls)
					node.add_child(child)
					child.set_owner(parent_scene)
				
				update_node(parent_scene, child, child_info, depth+1, _as_controls, _print)
		
		if "button" in info.tags:
			node._update_state()
		

# returns first visible layer, otherwise returns first layer
func get_default_layer(d:Dictionary=data) -> Dictionary:
	for l in d.layers:
		if l.visible:
			return l
	return d.layers[0] 

func _v(d:Dictionary) -> Vector2:
	return Vector2(d.x, d.y)

