tool
extends EditorImportPlugin

var plugin:EditorPlugin

func _init(p).():
	plugin = p

func get_importer_name(): return "limage.import.plugin"
func get_visible_name(): return "Limage"
func get_recognized_extensions(): return ["psd", "kra", "ora"]
func get_save_extension(): return "tres"
func get_resource_type(): return "Resource"
func get_preset_count(): return 1
func get_preset_name(i): return "Default"
func get_import_options(i):
	return [
		{name="format",default_value="PNG",type=TYPE_STRING,property_hint=PROPERTY_HINT_ENUM,hint_string="PNG,WEBP,JPEG,TGA,BMP"},
		
		{name="scale",default_value=1.0,type=TYPE_REAL,property_hint=PROPERTY_HINT_RANGE,hint_string="0.125,4.0"},
		{name="padding",default_value=1,type=TYPE_INT,property_hint=PROPERTY_HINT_RANGE,hint_string="0,4"},
		{name="origin",default_value=Vector2(0.5,1.0),type=TYPE_VECTOR2},
		{name="seperator",default_value="-",type=TYPE_STRING,property_hint=PROPERTY_HINT_ENUM,hint_string="-,/"},
		
		{name="quantize/enabled",default_value=false,type=TYPE_BOOL},
		{name="quantize/method",default_value=3,property_hint=PROPERTY_HINT_ENUM,hint_string="mediancut,maxcoverage,fastoctree,libimagequant"},
		{name="quantize/colors",default_value=256,property_hint=PROPERTY_HINT_RANGE,hint_string="2,256"},
		
		{name="PNG/optimize",type=TYPE_BOOL,default_value=true},
		
		{name="WEBP/lossless",default_value=true,type=TYPE_BOOL},
		{name="WEBP/method",default_value=3,type=TYPE_INT,property_hint=PROPERTY_HINT_ENUM,hint_string="0 fast & low quality,1,2,3,4,5,6 slow & high quality"},
		{name="WEBP/quality",default_value=80,type=TYPE_INT,property_hint=PROPERTY_HINT_RANGE,hint_string="0,100"},
		
		{name="JPEG/optimize",default_value=true,type=TYPE_BOOL},
		{name="JPEG/quality",default_value=75,type=TYPE_INT,property_hint=PROPERTY_HINT_RANGE,hint_string="0,95"},
		
		{name="texture/storage",default_value=ImageTexture.STORAGE_RAW,type=TYPE_INT,property_hint=PROPERTY_HINT_ENUM,hint_string="Uncompressed,Compress Lossy,Compress Lossless"},
		{name="texture/lossy_quality",default_value=0.7,type=TYPE_REAL,property_hint=PROPERTY_HINT_RANGE,hint_string="0.0,1.0"},
		{name="texture/flags",default_value=Texture.FLAGS_DEFAULT,type=TYPE_INT,property_hint=PROPERTY_HINT_FLAGS,hint_string="Mipmaps,Repeat,Filter,Anisotropic,sRGB,Mirrored Repeat"},
		
		{name="debug/print",default_value=false,type=TYPE_BOOL,usage=PROPERTY_USAGE_DEFAULT},
		{name="debug/skip_images",default_value=false,type=TYPE_BOOL,usage=PROPERTY_USAGE_DEFAULT},
		{name="debug/remove_image_files",default_value=true,type=TYPE_BOOL,usage=PROPERTY_USAGE_DEFAULT},
		{name="debug/binary_scene",default_value=false,type=TYPE_BOOL,usage=PROPERTY_USAGE_DEFAULT},
	]

func get_option_visibility(option, options):
	return true
#	if option.begins_with("texture/PNG/"): return options["texture/format"] == "PNG"
#	if option.begins_with("texture/WEBP/"): return options["texture/format"] == "WEBP"
#	if option.begins_with("texture/JPEG/"): return options["texture/format"] == "JPEG"

func import(source_file, save_path, options, platform_variants, gen_files):
	var limage = Limage.new()
	limage.file_path = source_file
	limage.file_modified_time = str(File.new().get_modified_time(source_file))
	
	for option in options:
		var prop = option.replace("/", "_").to_lower()
#		prints("set ", prop, " to ", options[option])
		limage[prop] = options[option]
	
	var save_to:String = save_path + "." + get_save_extension()
	
	if File.new().file_exists(source_file):
		if source_file.begins_with("res://"):
			limage.base_dir = source_file.get_base_dir()
		elif save_to.begins_with("res://"):
			limage.base_dir = save_to.get_base_dir()
		
		load("res://addons/limage/gen/L_TextureGen.gd").new(limage).generate()
		load("res://addons/limage/gen/L_DataGen.gd").new(limage).generate()
		load("res://addons/limage/gen/L_ScriptGen.gd").new(limage).generate()
		load("res://addons/limage/gen/L_SceneGen.gd").new(limage).generate()
	
	print("saved", limage)
	return ResourceSaver.save(save_to, limage)

#func _rescan():
#	var fs = plugin.get_editor_interface().get_resource_filesystem()
#	fs.update_script_classes()
#	fs.scan_sources()
#	fs.scan()
