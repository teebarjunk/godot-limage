tool

var li:Limage

func _init(l:Limage):
	li = l

func generate():
	var path = li.get_scene_name()
	var f:File = File.new()
	if false and f.file_exists(path):
		_update(path)
	else:
		_create(path)

func _update(path):
	pass

func _create(path):
	var scene:Node2D
	var script_path = li.get_output_dir().plus_file(li.get_fname() + ".gd")
	if File.new().file_exists(script_path):
		scene = load(script_path).new()
	else:
		scene = Node2D.new()
	
	scene.set_name(li.get_fname())
	
	for i in range(len(li.data.root.layers)-1,-1,-1):
		_create_layer(scene, scene, li.data.root.layers[i])
	
	# create points
	_create_points(scene, scene, li.data.root)
	
	var packed_scene = PackedScene.new()
	if packed_scene.pack(scene) == OK:
		if ResourceSaver.save(path, packed_scene) == OK:
			return
	push_error("An error occurred while saving the scene to disk.")
	return

func _create_points(root:Node, parent:Node, data:Dictionary):
	if "points" in data:
		for pi in data.points:
			var n:Node
			if "node" in pi.tags:
				n = ClassDB.instance(pi.tags.node)
			else:
				n = Node2D.new()
			
			parent.add_child(n)
			n.set_owner(root)
			
			n.set_name(pi.name)
			n.set_position(pi.position)
			
			# group
			if "group" in pi.tags:
				n.add_to_group(pi.tags.group, true)

func create_sprite(root:Node, parent:Node, data:Dictionary) -> Sprite:
	var s:Sprite = Sprite.new()
	
	# todo: apply to more than just a sprite
	
	# create local texture
	var image = Image.new()
	image.load(data.texture_path)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	texture.set_local_to_scene(true)
	texture.storage = li.texture_storage
	texture.lossy_quality = li.texture_lossy_quality
	texture.flags = li.texture_flags
	s.set_texture(texture)
	
	# remove the old image
	if li.debug_remove_image_files:
		Directory.new().remove(data.texture_path)
	
	s.set_name(data.name)
	s.set_position(data.position)
	s.set_centered(false)
	s.set_offset(-data.origin)
	
	if parent:
		parent.add_child(s)
		s.set_owner(root)
	
	_create_points(root if root else s, s, data)
	
	return s

func create_node(data:Dictionary) -> Node:
	var n:Node = Node2D.new()
	n.set_name(data.name)
	n.set_position(data.position)
	return n

func _create_layer(root:Node, parent:Node, data:Dictionary):
	var layer:Node2D
	
	if "texture" in data:
		layer = create_sprite(root, parent, data)
	else:
		layer = create_node(data)
		parent.add_child(layer)
		layer.set_owner(root)
	
#	layer.set_visible(data.visible)
#	layer.set_modulate(Color(1.0, 1.0, 1.0, data.opacity))
	
	
	layer.set_meta("limage", data)
	
	if "layers" in data:
		if "options" in data.tags:
			pass
		
		elif "toggles" in data.tags:
			pass
		
		else:
			for i in range(len(data.layers)-1, -1, -1):
				_create_layer(root, layer, data.layers[i])
