extends "res://data/cool_guy.gd"

var _time = 0.0
var _offset = 0.0

func _ready():
	_time = rand_range(0.0, 999.0)
	_offset = rand_range(-.1, .1)

func _process(delta):
	_time += delta
	self.rotation = _offset + (sin(_time) + sin(_time*2.0) + sin(_time*.25)) * .01
