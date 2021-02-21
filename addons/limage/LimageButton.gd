tool
extends Node
class_name LimageButton

signal pressed
signal released
signal entered
signal exited
signal toggled

export(bool) var disabled:bool = false setget set_disabled
var _hovered:bool = false
var _pressed:bool = false
var _parent

func _ready():
	while true:
		_parent = get_parent()
		if "limage" in _parent:
			break
	_update_state()

func set_disabled(v:bool):
	disabled = v
	_update_state()

func get_state():
	if disabled:
		return "disabled"
	elif _pressed:
		return "pressed"
	elif _hovered:
		return "hover"
	else:
		return "normal"

func _update_state():
	var state = get_state()
	for child in get_children():
		child.visible = child.name == state

func get_color_at(sprite, mouse_pos:Vector2) -> Color:
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
	
	return Color.transparent

func _unhandled_input(event):
#func _input(event):
	if not self.visible:
		return
	
	if event is InputEventMouseMotion:
		var mask = self if "texture" in self and self.texture != null else get_node_or_null("mask")
		if not mask:
			mask = get_node_or_null("normal")
		
		var over = get_color_at(mask, event.position).a > .5
	
#		print(get_color_at(mask, event.position))
		
		if over:
			get_tree().set_input_as_handled()
			
			if not _hovered:
				_hovered = true
				_update_state()
				emit_signal("entered")
				_parent.emit_signal("button_entered", name)
		else:
			if _hovered:
				get_tree().set_input_as_handled()
				_hovered = false
				_update_state()
				emit_signal("exited")
				_parent.emit_signal("button_exited", name)
			
	
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if _hovered:
			get_tree().set_input_as_handled()
			
			if event.pressed and not _pressed:
				_pressed = true
				_update_state()
				emit_signal("pressed")
				_parent.emit_signal("button_pressed", name)
			
		if not event.pressed and _pressed:
			get_tree().set_input_as_handled()
			
			_pressed = false
			_update_state()
			emit_signal("released")
			_parent.emit_signal("button_released", name)
