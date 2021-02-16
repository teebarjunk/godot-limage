tool
extends PanelContainer

onready var btn_gen = $VBoxContainer/HBoxContainer/generate
onready var chk_force_update = $VBoxContainer/HBoxContainer/force_update
onready var chk_skip_images = $VBoxContainer/HBoxContainer/skip_images
onready var txt_output = $VBoxContainer/PanelContainer/output

func _ready():
	var _e
	_e = btn_gen.connect("pressed", self, "_pressed")

func _pressed():
	txt_output.bbcode_enabled = true
	txt_output.bbcode_text = ""
	var path:String = ProjectSettings.globalize_path("res://addons/limage/python/PsdProcessor.py")
	var args = [path, chk_force_update.pressed, chk_skip_images.pressed]
	var output = []
	OS.execute("python3", args, true, output, true)
	for line in output:
		txt_output.bbcode_text += line.strip_edges(false, true) + "\n"
	txt_output.bbcode_text += "all done."
