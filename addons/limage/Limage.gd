tool
class_name Limage, "res://addons/limage/layer.png" extends Resource

export(String, FILE, GLOBAL, "*.psd,*.kra,*.ora") var file_path:String = ""
export var file_modified_time:String = ""

var format:String = "PNG" setget set_format

var layers_as_scenes:bool = false

# format: PNG
var png_optimize:bool = true
# format: WEBP
var webp_lossless:bool = true
var webp_method:int = 3
var webp_quality:int = 80
# format: JPEG
var jpeg_optimize:bool = true
var jpeg_quality:int = 75
# format: TGA (TODO)
# format: BMP (TODO)

# quantize
var quantize_enabled:bool = false
var quantize_method:int = 3
var quantize_colors:int = 255

var scale:float = 1.0
var padding:int = 1
var origin:Vector2 = Vector2(.5, 1.0)
var seperator:String = "-"

# texture file settings
var texture_storage:int = ImageTexture.STORAGE_COMPRESS_LOSSLESS
var texture_lossy_quality:float = 0.7
var texture_flags:int = Texture.FLAGS_DEFAULT

var debug_print:bool = false
var debug_skip_images:bool = false
var debug_binary_scene:bool = false # store as smaller ".scn" instead of larger ".tscn" 
var debug_remove_image_files:bool = true

var base_dir:String

export(Dictionary) var data:Dictionary = {}

func set_format(f):
	format = f
	property_list_changed_notify()

func _get_property_list():
	var out:Array = []
	
	out.append_array([
		{name="Texture",type=TYPE_NIL,usage=PROPERTY_USAGE_GROUP,hint_string="texture_"},
		{name="format",type=TYPE_STRING,value="PNG",hint=PROPERTY_HINT_ENUM,hint_string="PNG,WEBP,JPEG,TGA,BMP"},
		{name="layers_as_scenes",type=TYPE_BOOL,value=false},
		{name="scale",type=TYPE_REAL,hint=PROPERTY_HINT_RANGE,hint_string="0.125,4.0"},
		{name="padding",type=TYPE_INT,hint=PROPERTY_HINT_RANGE,hint_string="0,4"},
		{name="origin",type=TYPE_VECTOR2,value=Vector2(0.5,1.0)},
		{name="seperator",type=TYPE_STRING,hint=PROPERTY_HINT_ENUM,hint_string="-,/"}])
	
	out.append_array([
		{name="Quantize",type=TYPE_NIL,usage=PROPERTY_USAGE_GROUP,hint_string="quantize_"},
		{name="quantize_enabled",type=TYPE_BOOL,hint=""},
		{name="quantize_method",type=TYPE_INT,hint=PROPERTY_HINT_ENUM,hint_string="mediancut,maxcoverage,fastoctree,libimagequant"},
		{name="quantize_colors",type=TYPE_INT,hint=PROPERTY_HINT_RANGE,hint_string="2,256"},
	])
	
	match format:
		"PNG": out.append_array([
			{name="PNG",type=TYPE_NIL,usage=PROPERTY_USAGE_GROUP,hint_string="png_"},
			{name="png_optimize",type=TYPE_BOOL,value=true}])
		
		"WEBP": out.append_array([
			{name="WEBP",type=TYPE_NIL,usage=PROPERTY_USAGE_GROUP,hint_string="webp_"},
			{name="webp_lossless",type=TYPE_BOOL,value=true},
			{name="webp_method",type=TYPE_INT,value=3,hint=PROPERTY_HINT_ENUM,hint_string="0 fast & low quality,1,2,3,4,5,6 slow & high quality"},
			{name="webp_quality",type=TYPE_INT,value=80,hint=PROPERTY_HINT_RANGE,hint_string="0,100"}])
		
		"JPEG": out.append_array([
			{name="JPEG",type=TYPE_NIL,usage=PROPERTY_USAGE_GROUP,hint_string="jpeg_"},
			{name="jpeg_optimize",type=TYPE_BOOL,value=true},
			{name="jpeg_quality",type=TYPE_INT,value=75,hint=PROPERTY_HINT_RANGE,hint_string="0,95"}])
	
	out.append_array([
		{name="Texture",type=TYPE_NIL,usage=PROPERTY_USAGE_GROUP,hint_string="texture_"},
		{name="texture_storage",type=TYPE_INT,hint=PROPERTY_HINT_ENUM,hint_string="Uncompressed,Compress Lossy,Compress Lossless"},
		{name="texture_lossy_quality",type=TYPE_REAL,hint=PROPERTY_HINT_RANGE,hint_string="0.0,1.0"},
		{name="texture_flags",type=TYPE_INT,hint=PROPERTY_HINT_FLAGS,hint_string="Mipmaps,Repeat,Filter,Anisotropic,sRGB,Mirrored Repeat"},
	])
	
	out.append_array([
		{name="Debug",type=TYPE_NIL,usage=PROPERTY_USAGE_GROUP,hint_string="debug_"},
		{name="debug_print",type=TYPE_BOOL,usage=PROPERTY_USAGE_DEFAULT},
		{name="debug_skip_images",type=TYPE_BOOL,usage=PROPERTY_USAGE_DEFAULT},
		{name="debug_binary_scene",type=TYPE_BOOL,usage=PROPERTY_USAGE_DEFAULT},
		{name="debug_remove_image_files",type=TYPE_BOOL,usage=PROPERTY_USAGE_DEFAULT},
	])
	
	return out

func get_fname() -> String:
	return file_path.get_file().rsplit(".", true, 1)[0]

func get_output_dir() -> String:
	return base_dir.plus_file(get_fname())

func get_scene_path(file:String):
	return get_output_dir().plus_file(file + (".scn" if debug_binary_scene else ".tscn"))

func get_scene_dir_path(dir:String, file:String):
	var out = get_output_dir().plus_file(dir)
	var d:Directory = Directory.new()
	if not d.dir_exists(out):
		d.make_dir(out)
	return out.plus_file(file + (".scn" if debug_binary_scene else ".tscn"))

func get_scene_name() -> String:
	return get_scene_path(get_fname())

func get_child_names(layer:Dictionary) -> PoolStringArray:
	var out = PoolStringArray()
	if has_layers(layer):
		for l in layer.layers:
			out.append(l.name)
	return out

func get_child(layer:Dictionary, name:String) -> Dictionary:
	if has_layers(layer):
		for child in layer.layers:
			if child.name == name:
				return child
	return {}

func has_layers(layer:Dictionary) -> bool:
	return "layers" in layer and layer.layers
	
func on_all_layers(obj:Object, fname:String):
	var fr = funcref(obj, fname)
	for layer in _get_all_layers(data.root, []):
		fr.call_func(layer)

func _get_all_layers(d:Dictionary, out:Array):
	if has_layers(d):
		for l in d.layers:
			out.append(l)
			_get_all_layers(l, out)
	return out
