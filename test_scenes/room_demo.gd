tool
extends LimageNode

var open = false
var cursors:Limage = preload("res://data/cursor.tres")

func _ready():
	var _e
	_e = connect("button_pressed", self, "button_pressed", [true])
	_e = connect("button_released", self, "button_pressed", [false])
	_e = connect("button_entered", self, "button_entered", [true])
	_e = connect("button_exited", self, "button_entered", [false])

func _process(_delta):
	pass
#	Input.set_default_cursor_shape(Input.CURSOR_CROSS)

func button_pressed(name:String, reverse):
	if not reverse:
		prints("clicked", name)
	
	if name == "door":
		if reverse:
			open = not open
			if open:
				$AnimationPlayer.play("open")
			else:
				$AnimationPlayer.play_backwards("open")

func button_entered(_name:String, out:bool):
	if out:
		cursors.set_layer_as_cursor("finger")
	else:
		cursors.set_layer_as_cursor("arrow")
