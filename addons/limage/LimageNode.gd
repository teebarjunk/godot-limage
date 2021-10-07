tool
class_name LimageNode, "res://addons/limage/layer.png" extends Node2D

func reset():
	pass

# meant to be overriden
#func _scene_path(name:String): return filename.get_base_dir().plus_file(name + ".tscn")
#func _to_path(name:String): return 

func _find_scene(scene:String) -> String:
	var path = filename.get_base_dir()
	var s = path.plus_file(scene + ".tscn")
	if File.new().file_exists(s): return s
	return path.plus_file(scene + ".scn")


#func _get_configuration_warning():
#	return "nevermind."

func _penultimate(path:String):
	path = path.rsplit("/", true, 1)[0]
	if "/" in path:
		return find_node(path, false)
	elif has_node(path):
		return get_node(path)
	return null

func _get_toggle(node_path:String) -> bool:
	return get_node_or_null(node_path) != null

func _set_toggle(node_path:String, enable:bool):
	var node = get_node_or_null(node_path)
	
	if enable:
		if not node:
			var parent = _penultimate(node_path)
			var path = _find_scene("toggles/" + node_path.replace("/", "-"))
			node = load(path).instance()
			parent.add_child(node)
			node.set_owner(self if owner == null else owner)
			
	else:
		if node:
			node.get_parent().remove_child(node)
			node.queue_free()

func _get_option(node_path:String) -> String:
	var parent = get_node_or_null(node_path)
	if parent and parent.get_child_count() > 0:
		return parent.get_child(0).name
	return ""

func _set_option(node_path:String, option_name:String):
	if _get_option(node_path) == option_name:
		return
	
	var parent = get_node_or_null(node_path)
	if not parent:
		return
	
	var active_option:Node2D = null
	
	for option in parent.get_children():
		parent.remove_child(option)
		option.queue_free()
	
	if active_option == null:
#		var image_name = "%s-%s" % [node_path.replace("/", "-"), option_name]
		var path = _find_scene("options/%s-%s" % [node_path.replace("/", "-"), option_name])
		var node = load(path).instance()
		parent.add_child(node)
		if Engine.editor_hint:
			node.set_owner(self if owner == null else owner)
#		load_to_node(image_name, active_option)
	
	property_list_changed_notify()

func _get_hovered_layer(l:Node, pos:Vector2):
	if not l is Node2D or not l.visible:
		return null
	
	# go backwards through children (top -> bottom)
	for i in range(l.get_child_count()-1, -1, -1):
		var clr = _get_hovered_layer(l.get_child(i), pos)
		if clr != null:
			return clr
	
	if l is Sprite:
		var clr = get_color_at(l, pos)
		if clr != null and clr.a > 0.0:
			return {node=l, color=clr}
	
	return null

# get layer + color that mouse cursor is over
# {color, node}
func get_hovered_layer(pos=null):
	if pos == null:
		pos = get_viewport().get_mouse_position()
	return _get_hovered_layer(self, pos)

func has_tag(n:Node, tag:String):
	return n.has_meta("tags") and tag in n.get_meta("tags")
	
func get_tag(n:Node, tag:String, default=null):
	if n.has_meta("tags"):
		return n.get_meta("tags").get(tag, default)
	return default

func get_color_at(sprite, mouse_pos:Vector2):
	if sprite and sprite.texture:
		var r = sprite.get_rect()
		var mp:Vector2
		
		if sprite is Control:
			mp = sprite.get_global_mouse_position()
			r = sprite.get_global_rect()
#			mp = sprite.get_global_transform().xform_inv(mouse_pos)
#			mp /= sprite.rect_scale * 2.0
#			mp = mouse_pos
		else:
			mp = sprite.to_local(mouse_pos)
			r = sprite.get_rect()
		
#		print(sprite.get_rect(), sprite.get_global_rect())
		
		if r.has_point(mp):
			var image:Image = sprite.texture.get_data()
			image.lock()
			var pixel = image.get_pixelv(mp - r.position)
			image.unlock()
			return pixel
	
	return null
