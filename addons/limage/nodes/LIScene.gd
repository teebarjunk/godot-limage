class_name LIScene
extends LimageNode

var hovered:Node2D

func _process(delta):
	var c = get_hovered_layer()
	var h = c.node if c and has_tag(c.node, "button") else null
	if hovered != h:
		if hovered:
			hovered.modulate = Color.white
			hovered = null
		
		hovered = h
		
		if hovered:
			hovered.modulate = Color.yellow
	
	if hovered and Input.is_mouse_button_pressed(BUTTON_LEFT):
		pressed(c.node.name)

func pressed(name:String):
	print(name)
