tool
extends EditorPlugin

const Dock = preload("res://addons/limage/Dock.tscn")
var dock

func _enter_tree():
	dock = Dock.instance()
	dock.plugin = self
	# Add the main panel to the editor's main viewport.
	get_editor_interface().get_editor_viewport().add_child(dock)
	# Hide the main panel. Very much required.
	make_visible(false)
	
#	var ic_node2d = get_editor_interface().get_base_control().get_icon("Node2D", "EditorIcons")
#	add_custom_type("LimageNode", "Node2D", load("res://addons/limage/LimageNode.gd"), ic_node2d)

func _exit_tree():
	if dock:
		dock.queue_free()
	
#	remove_custom_type("LimageNode")

func has_main_screen():
	return true

func make_visible(visible):
	if dock:
		dock.visible = visible

func get_plugin_name():
	return "Limage"

#func get_plugin_icon():
#	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")
