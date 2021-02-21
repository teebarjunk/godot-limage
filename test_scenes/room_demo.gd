tool
extends LimageNode

var open = false
var cursors:Limage = preload("res://data/cursor.tres")

var _timer:float = 0
var _picture_fell:bool = false
var _time:float = 0

func _ready():
	var _e
	_e = connect("button_pressed", self, "button_pressed", [true])
	_e = connect("button_released", self, "button_pressed", [false])
	_e = connect("button_entered", self, "button_entered", [true])
	_e = connect("button_exited", self, "button_entered", [false])
	
	$vault.visible = false
	
	cursors.set_layer_as_cursor("arrow")

func _process(_delta):
	_timer -= _delta
	_time += _delta
	if _timer <= 0:
		_timer = rand_range(.2, .3)
		$lights/lamp.color.a = rand_range(.2, .4)
	
	$lights/window.color.a = (sin(_time)*.5+.5 + sin(_time*3.0)*.5+.5 + sin(_time*.25)*.5+.5) / 3.0
	
func button_pressed(name:String, released):
	if released:
		return
	
	if name == "door" and not _picture_fell:
		_picture_fell = true
		$AnimationPlayer.play("picture")
		$vault.visible = true
	
	elif name == "vault":
		OS.alert("You're going to jail now!", "Illegal crime detected!")

func button_entered(_name:String, out:bool):
	if out:
		cursors.set_layer_as_cursor("finger")
	else:
		cursors.set_layer_as_cursor("arrow")
