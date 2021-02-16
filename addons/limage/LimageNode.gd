tool
extends Node
class_name LimageNode

signal button_pressed(id)
signal button_released(id)
signal button_entered(id)
signal button_exited(id)

export(Resource) var limage:Resource
export(bool) var _force_update:bool = false setget _do_update
export(bool) var _as_controls:bool = false
export(bool) var _print:bool = false

func _do_update(v:bool):
	_force_update = v
	if not _force_update:
		force_update()

func has_limage() -> bool:
	return limage != null and limage is Limage

func force_update():
	if has_limage():
		limage.update_scene(self, _as_controls, _print)

func get_toggle(layer_path:String) -> bool:
	return get_node_or_null(layer_path) != null

func get_option(layer_path:String) -> String:
	if has_limage():
		var info = limage.get_layer(layer_path)
		var node = get_node_or_null(layer_path)
		if info and node:
			var default = limage.get_default_layer(info)
			return node.option == default.texture
	return ""

func set_toggle(layer_path:String, enable:bool):
	if has_limage():
		var info = limage.get_layer(layer_path)
		var node = get_node_or_null(layer_path)
		if info:
			if node:
				if not enable:
					node.get_parent().remove_child(node)
					node.queue_free()
			else:
				var parent = self
				if "/" in layer_path:
					var parent_path = layer_path.rsplit("/", true, 1)[0]
					parent = get_node_or_null(parent_path)
				
				if enable and parent:
					node = limage.get_node_type(info, false)
					parent.add_child(node)
					node.set_owner(self)
					limage.apply_name(node, info)
					limage.apply_texture(node, info)
					limage.apply_position(node, info)

func set_option(layer_path:String, new_layer:String):
	if new_layer == "":
		return
	
	var info = limage.get_layer(layer_path)
	if info:
		var n = get_node_or_null(layer_path)
		if n:
			var f2 = limage.get_layer(new_layer, info)
			limage.apply_texture(n, f2)
			limage.apply_position(n, f2)
		else:
			prints("couldnt find node:", layer_path)
	else:
		prints("couldnt find layer:", layer_path)

#func _get_property_list():
#	var out = []
#	if has_limage():
#		for layer in limage.get_layers():
#			if "toggles" in layer.tags:
#				var var_name = "_%s" % limage.get_varname(layer)
#				out.append({
#					"name": layer.name,
#					"type": TYPE_NIL,
#					"hint_string": var_name,
#					"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
#				})
#
#				for child in layer.layers:
#					out.append({
#						"name": "_%s" % limage.get_varname(child),
#						"type": TYPE_BOOL,
#						"usage": PROPERTY_USAGE_DEFAULT
#					})
#	return out
#
#func set(property, value):
#	prints("SET2", property, value)
#
#func _set(property, value):
#	prints("SET", property, value)
