tool
extends Node2D

var a_quad:int = 0
var a_quad2:int = 2

func _get_property_list(): 
	return [{
		name = "Rotate",
		type = TYPE_NIL,
		hint_string = "a_",
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	},
	{
		"hint": PROPERTY_HINT_NONE,
		"usage": PROPERTY_USAGE_DEFAULT,
		"name": "a_quad",
		"type": TYPE_STRING
	},
	{
		"hint": PROPERTY_HINT_NONE,
		"usage": PROPERTY_USAGE_DEFAULT,
		"name": "a_quad2",
		"type": TYPE_STRING
	}]

func _get(property):
	prints("get", property)
	return a_quad

func _set(property, value):
	prints("set", property, "to", value)
	a_quad = value
