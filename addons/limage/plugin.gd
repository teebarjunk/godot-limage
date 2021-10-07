tool
extends EditorPlugin

const LimageImporter = preload("res://addons/limage/LimageImporter.gd")
const Icon = preload("res://addons/limage/layer.png")
var limage_importer = LimageImporter.new(self)

func get_plugin_icon(): return Icon
func get_plugin_name(): return "Limage"

func _enter_tree():
	add_custom_type("Limage", "Resource", Limage, Icon)
	add_import_plugin(limage_importer)

func _exit_tree():
	remove_custom_type("Limage")
	remove_import_plugin(limage_importer)
