tool
extends PanelContainer

const VERSION = "0.2.1"

onready var btn_gen = $VBoxContainer/HBoxContainer/generate
onready var chk_force_update = $VBoxContainer/HBoxContainer/force_update
onready var chk_skip_images = $VBoxContainer/HBoxContainer/skip_images
onready var txt_output = $VBoxContainer/PanelContainer/output

var plugin:EditorPlugin

func _ready():
	var _e
	_e = btn_gen.connect("pressed", self, "_pressed")

func _pressed():
	txt_output = $VBoxContainer/PanelContainer/output
	txt_output.bbcode_enabled = true
	txt_output.bbcode_text = ""
	
	var c1 = Color().from_hsv(randf(), .5, 1).to_html()
	var c2 = Color().from_hsv(randf(), .5, 1).to_html()
	txt_output.bbcode_text += "[color=#%s]LIMAGE[/color] [color=#%s]v%s[/color]\n" % [c1, c2, VERSION]
	
	var path:String = ProjectSettings.globalize_path("res://addons/limage/python/PsdProcessor.py")
	var args = [path, chk_force_update.pressed, chk_skip_images.pressed]
	var output = []
	OS.execute("python3", args, true, output, true)
	for line in output:
		txt_output.bbcode_text += line.strip_edges(false, true) + "\n"
	
	var ei = plugin.get_editor_interface()
	var fs = ei.get_resource_filesystem()
	
	var files = []
	var dir = Directory.new()
	dir.open("res://data")
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if not file.begins_with("."):
			fs.update_file("res://data" + file)
			txt_output.bbcode_text += "[color=cyan]updating: %s[/color]\n" % file
	
	dir.list_dir_end()
	
	fs.update_script_classes()
	fs.scan()
	
	txt_output.bbcode_text += "[color=#%s]all done.[/color]" % Color.yellowgreen.to_html()
