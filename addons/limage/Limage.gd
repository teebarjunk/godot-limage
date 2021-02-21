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
			Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, -origin)
		else:
			prints(layer.name, "has no texture")
	else:
		prints("no layer ", name)

func get_node_type(layer:Dictionary, _as_controls:bool):
	if "node" in layer.tags:
		if ClassDB.class_exists(layer.tags.node):
			return ClassDB.instance(layer.tags.node)
		else:
			push_warning("No node: %s" % layer.tags.node)
	
	var node:Node
	if "texture" in layer or "options" in layer.tags:
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
	if "color" in n:
		n.color.a = l.opacity / 255.0
	elif "opacity" in n: # Sprite3D
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
	if "position" in n:
		n.position = _v(d.position)
		
		if "offset" in n and not n is Light2D:
			n.offset = -_v(d.origin)
	
	elif "rect_position" in n:
		n.rect_position = _v(d.position) + _v(d.origin)
		n.rect_pivot_offset = -_v(d.origin)
	
	else:
		prints("couldn't set position", n, d.name)

func update_node(top_node:Node, _as_contols:bool=false, _print:bool=true):
	_update_node(top_node, top_node, data, 0, _as_contols, _print)

func _update_node(top_node:Node, node:Node, info:Dictionary, depth:int=0, _as_controls:bool=false, _print:bool=true):
	apply_name(node, info)
	
	if "layer_info" in node:
		node.layer_info = info
	
	if _print:
		print("\t".repeat(depth), node.name)
	
	apply_visible(node, info)
	apply_opacity(node, info)
	
	if "options" in info.tags:
		var default = get_default_layer(info)
		node.option = default.name
		apply_texture(node, default)
		apply_position(node, default)
	
	else:
		# update settings
		if node != top_node:
			apply_position(node, info)
			apply_texture(node, info)
		
		# create and/or update child layers
		if "layers" in info:
			for child_info in info.layers:
				if "toggles" in info.tags and not child_info.visible:
					continue
				
				var child = node.get_node_or_null(child_info.name)
				# create new
				if child == null:
					child = get_node_type(child_info, _as_controls)
					node.add_child(child)
					if top_node.owner == null:
						child.set_owner(top_node)
					else:
						child.set_owner(top_node.owner)
				
				_update_node(top_node, child, child_info, depth+1, _as_controls, _print)
		
		if "button" in info.tags:
			node._update_state()

# returns first visible layer, otherwise returns first layer
func get_default_layer(d:Dictionary=data) -> Dictionary:
	for l in d.layers:
		if l.visible:
			return l
	return d.layers[0] 

# recursively passes every layer through the given function
func call_on_descendants(fr:FuncRef, args:Array=[], d:Dictionary=data):
	if "layers" in d:
		for child in d["layers"]:
			fr.call_func(child, args)
			call_on_descendants(fr, args, child)

func _v(d:Dictionary) -> Vector2:
	return Vector2(d.x, d.y)

