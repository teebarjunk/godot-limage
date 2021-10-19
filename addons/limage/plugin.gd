tool
extends EditorPlugin

const Icon = preload("res://addons/limage/layer.png")
func get_plugin_icon(): return Icon
func get_plugin_name(): return "Limage"

const LimageImporter = preload("res://addons/limage/LimageImporter.gd")
var limage_importer = LimageImporter.new(self)

func _enter_tree():
	add_custom_type("Limage", "Resource", Limage, Icon)
	add_import_plugin(limage_importer)

func _exit_tree():
	remove_custom_type("Limage")
	remove_import_plugin(limage_importer)
