import PIL
from PIL import Image
from PIL import features
from psd_tools import PSDImage
from psd_tools.constants import Tag
# from psd_tools.constants import BlendMode
import json, math, sys
from pathlib import Path
import util, godot
from util import get
from classes import Vec2

__version__ = "0.2"

WEBP_SUPPORTED:bool = features.check_module('webp')
if not WEBP_SUPPORTED:
	print(f"PILLOW v{PIL.__version__}")
	print(f"WEBP support: {WEBP_SUPPORTED}")
	print(f"  libwebp library might not be installed")
	print(f"  Ubuntu: sudo apt-get install -y libwebp-dev")

DEFAULT_SETTINGS:dict = {
	"path": "",						# location of psd
	"seperator": "-",				# change to "/" to folderize
	
	"texture_dir": None,			# if set, saves textures here
	"data_dir": "data",				# if set, saves layer data here
	# "script_dir": None,			# if set, saves godot scripts here
	
	# texture related
	"scale": 1,						# rescale textures
	"mask_scale": 1.0,#.25,			# shrink masks?
	"origin": [0, 0],				# multiplied by size of texture
	
	# can really decrease file size, but at cost of color range.
	# https://pillow.readthedocs.io/en/stable/reference/Image.html#PIL.Image.Image.quantize
	"quantize": False,				# decrease size + decrease quality
	
	# https://pillow.readthedocs.io/en/stable/handbook/image-file-formats.html
	# https://docs.godotengine.org/en/stable/getting_started/workflow/assets/importing_images.html
	"format": "WEBP",
	
	"PNG": {
		"optimize": True,
	},
	
	"WEBP": {
		"lossless": True,
		"method": 3,
		"quality": 80
	},

	"JPEG": {
		"optimize": True,
		"quality": 80
	}
}
FORCE_UPDATE:bool = False if len(sys.argv) <= 1 else sys.argv[1] == "True"
SKIP_IMAGES:bool = False if len(sys.argv) <= 2 else sys.argv[2] == "True"
DIR_RESOURCES = Path("/".join(sys.argv[0].split("/")[:-4]))
LOOK_IN:str = "layered_images"

def file_time(path) -> str:
	return str(path.lstat().st_mtime)

def create_directory(path):
	if not path.exists() and str(path).startswith(str(DIR_RESOURCES)):
		print(f"creating directory: {path}")
		path.mkdir(parents=True, exist_ok=True)

def load_dict(local_path, default:object=None) -> object:
	path = DIR_RESOURCES / local_path
	if path.exists():
		with open(path, "r") as file:
			return json.load(file)
	return default

def save_dict(local_path, data:dict, indent:bool=True, loud:bool=True):
	path = DIR_RESOURCES / local_path
	create_directory(path.parents[0])
	with open(path, "w") as file:
		if indent:
			json.dump(data, file, indent=4)
		else:
			json.dump(data, file, separators=(',', ':'))
	print(f"saved: {local_path}")

def save_string(local_path, string:str):
	path = DIR_RESOURCES / local_path
	create_directory(path.parents[0])
	with open(path, "w", encoding="utf-8") as file:
		file.write(string)
	print(f"saved: {local_path}")

def save_image(local_path, image, format, extension_settings):
	path = DIR_RESOURCES / local_path
	create_directory(path.parents[0])
	image.save(path, format, **extension_settings)
	print(f"saved: {local_path}")

class PSDProcessor:
	# settings
	def get(self, key:str, default=None):
		return get(self.settings, key, get(DEFAULT_SETTINGS, key, default))
	
	def __init__(self, path, settings:dict):
		self.settings = settings
		self.update_image = True
		self.path = path
		
		# filename without extension
		self.file_name = self.path.stem# self.path.rsplit("/", 1)[1].rsplit(".", 1)[0]
	
		self.psd = PSDImage.open(self.path)
		self.wide, self.high = self.psd.size
		
		self.layers = []
		self.layer_info = {}
		self.texture_paths = []
		self.scenes = []
		self.name = self.get("name", self.file_name)
		self.output = {
			"name": self.name,
			"textures": self.texture_paths,
			"scenes": self.scenes
		}
		
		self.texture_dir = self.get("texture_dir")
		if self.texture_dir == None:
			self.texture_dir = f"textures/{self.name}"
		
		self.scale = self.get("scale")
		self.origin = Vec2(self.wide, self.high) * Vec2(self.get("origin"))
		self.mask_scale = self.scale * self.get("mask_scale")
		self.format = self.get("format")
		self.texture_extension = self.get("texture_extension", self.format.lower())
		self.extension_settings = dict(self.get(self.format, {}))
		self.structure = self.get("structure")
		self.data_dir = self.get("data_dir")
		
		# set default extension settings, if not set.
		if self.format in DEFAULT_SETTINGS:
			for key in DEFAULT_SETTINGS[self.format]:
				if not key in self.extension_settings:
					self.extension_settings[key] = DEFAULT_SETTINGS[self.format][key]
		
		layer_index = 0
		all_layers = list(self.psd.descendants())
		
		for l in list(all_layers):
			if l not in all_layers:
				continue
			
			# get name and tag data
			l.name, l._tags, l._child_tags, l._descendant_tags = util.parse_name(l.name)
			l.name = l.name if l.name != "" else f"LAYER_{layer_index}"
			l._index = layer_index
			layer_index += 1
			
			if "x" in l._tags:
				all_layers.remove(l)
				if l.kind == "group":
					for child in l.descendants():
						all_layers.remove(child)
				continue
			
			# remember old state
			l._old_visible = True if "visible" in l._tags else False if "!visible" in l._tags else l.visible
			l._old_opacity = l.opacity
			l._old_blend_mode = str(l.blend_mode).split(".")[1].lower()
			# force visible
			l.visible = True
			l.opacity = 255
			
			# get position + size
			x, y, r, b = l.bbox# self.get_bbox(l)
			x, y, r, b = max(x, 0), max(y, 0), min(r, self.wide), min(b, self.high)
			w = r - x
			h = b - y
			l._clamped_bbox = (x, y, r, b)
			l._size = Vec2(w, h)
			l._center = Vec2(x, y) + l._size * .5
			l._scale = self.scale
			l._origin = Vec2(x, y) + l._size * .5
			l._points = {}
			
		# update origins
		for l in list(all_layers):
			if l not in all_layers:
				continue
			
			if "point" in l._tags:
				pass
			
			if "origin" in l._tags:
				all_layers.remove(l)
				if l.parent == self.psd:
					self.origin = l._origin
				else:
					l.parent._origin = l._origin
			
			if "origins" in l._tags:
				all_layers.remove(l)
				for child_origin in l.descendants():
					all_layers.remove(child_origin)
					child = self.get_child(self.psd, child_origin.name)
					child._origin = child_origin._origin
					# print("set", child_origin.name, "origin to", child._origin)
		
		for l in list(all_layers):
			if l not in all_layers:
				continue
			
			# if merging, ignore lower data
			if "merge" in l._tags:
				for child in l.descendants():
					all_layers.remove(child)
			
			# determine if this is a group
			l._is_group = l.kind == "group" and not "merge" in l._tags
			if l._is_group:
				# pass on descendant data
				for child in l.descendants():
					for key in l._descendant_tags:
						if not key in child._tags:
							child._tags[key] = l._descendant_tags[key]
				
				# pass on child data
				for child in l:
					for key in l._child_tags:
						if not key in child._tags: 
							child._tags[key] = l._child_tags[key]
			
			del l._child_tags
			del l._descendant_tags
		
		for l in all_layers:
			l._path = self.get_layer_path(l)
			l._full_path = l._path.copy()
			l._full_path.append(l.name)
			
			if "scene" in l._tags:
				self.scenes.append(l)
			
			if not l._is_group and not "point" in l._tags:
				self.save_layer_image(l)
			
			# get rid of internally used keys
			for k in ["merge", "no_sep", "scene"]:
				if k in l._tags:
					del l._tags[k]
			
			l._global_position = Vec2(l._clamped_bbox[0], l._clamped_bbox[1])
			
		for l in all_layers:
			l._origin -= l._global_position # localize
			
			l._global_position += l._origin # offset origin
			l._global_position -= self.origin
			
			l._origin *= l._scale
			l._global_position *= l._scale
			
			l._output = {
				"name": l.name,
				"path": l._full_path,
				"tags": l._tags,
				"visible": l._old_visible,
				"opacity": l._old_opacity,
				"blend_mode": l._old_blend_mode,
				"global_position": l._global_position,
				"size": l._size * l._scale,
				# "scale": l._scale / self.scale,
				"origin": l._origin.negative()
			}
			
			if hasattr(l, "_texture"):
				l._output["scale"] = l._scale
				l._output["texture"] = l._texture
		
		self.all_layers = all_layers
		self.save_data()
	
	def was_modified(self, oldd:dict) -> bool:
		for key in self.settings:
			if key not in oldd:
				return False
		
		for key in oldd:
			if oldd[key] != self.settings[key]:
				return False
		
		return True
	
	def get_child(self, layer, child_name):
		for child in layer:
			if child.name == child_name:
				return child
		return None
	
	def save_data(self):
		if not self.data_dir:
			print("no 'data_dir' given. data won't be written to disk.")
			return
		
		for l in self.all_layers:
			if l._is_group:
				l._output["layers"] = [x._output for x in l if x in self.all_layers]
		
		# collect root layers
		output = {
			"name": self.file_name,
			"path": [],
			"tags": {},
			"visible": True,
			"opacity": 255,
			"size": Vec2(self.wide, self.high),
			"origin": Vec2(self.wide, self.high) * .5,
			"layers": [x._output for x in self.psd if x in self.all_layers],
			# "blend_mode": l._old_blend_mode,
			# "global_position": l._global_position,
		}
		
		# layer info
		local_path = self.data_path(self.name, "tres")
		tres_text = godot.TEMPLATE_TRES + json.dumps(output, indent=4)
		save_string(local_path, tres_text)
		
		# godot script
		has_script, script = godot.generate_script(self.all_layers)
		if has_script:
			script_name = self.name.replace(" ", "_")
			local_path = self.data_path(script_name, "gd")
			save_string(local_path, script)
	
	def data_path(self, local_path, extension):
		return f"{self.data_dir}/{local_path}.{extension}"
	
	def get_layer_path(self, layer) -> list:
		path = []
		while layer.parent != None and layer.parent != self.psd:
			path.insert(0, layer.parent.name)
			layer = layer.parent
		return path
	
	def save_layer_image(self, l):
		if self.texture_dir == None:
			return
		
		local_path = self.texture_dir + "/"
		
		# add path to file name
		if not self.structure in ["flat", "solo"] and len(l._path) > 0:
			sep = self.get("seperator")
			local_path += sep.join(l._path) + sep
		
		local_path += l.name
		local_path += "." + self.texture_extension
		
		is_mask = "mask" in l._tags
		scale = self.scale if not is_mask else self.mask_scale
		
		l._scale = scale
		l._texture = f"res://{local_path}"
		self.texture_paths.append(local_path)
		
		if self.update_image and not SKIP_IMAGES:
			image = l.composite(l._clamped_bbox)
			
			# Scale.
			if scale != 1:
				w, h = image.size
				w = math.ceil(w * scale)
				h = math.ceil(h * scale)
				image = image.resize((w, h), Image.NEAREST if is_mask else Image.LANCZOS)
			
			# Optional: Quantize (Can really reduce size, but at cost of colors.)
			# 0 = median cut 1 = maximum coverage 2 = fast octree
			if is_mask:
				image = image.quantize(colors=2, method=2, dither=Image.NONE)
				
			elif self.get("quantize"):
				image = image.quantize(method=3)
			
			# generate polygon
			if "poly" in l._tags:
				import genpoly
				poly_path = self.data_path(f"poly_{self.name}", "tscn")
				points = genpoly.get_points(image, l._texture)# str(DIR_RESOURCES / local_path), l._texture)
				save_string(poly_path, points)
			
			# RGBA -> RGB
			if self.format in ["JPEG"]:
				new_image = Image.new("RGB", image.size, (255, 255, 255))
				new_image.paste(image, mask=image.split()[3])
				image = new_image
			
			save_image(local_path, image, self.format, self.extension_settings)

def settings_changed(old, new):
	if len(old) != len(new):
		return True
	for k in new:
		if not k in old:
			return True
		if old[k] != new[k]:
			return True
	return False

directory = DIR_RESOURCES / LOOK_IN

if directory.exists():
	for file in list(directory.rglob('*.psd')):
		fname = file.stem
		fextension = file.suffix
		fpath = directory / file
		
		build_info_path = f"{LOOK_IN}/.lim_{fname}.json"
		build_info = load_dict(build_info_path, {"modified": "", "settings":{}})
		new_time = file_time(fpath)
		
		settings_path = f"{LOOK_IN}/{fname}.json"
		settings = load_dict(settings_path, {})
		
		if FORCE_UPDATE or\
			build_info["modified"] != new_time or\
			settings_changed(build_info["settings"], settings):
			
				PSDProcessor(fpath, settings)
				
				new_data = {
					"path": str(fpath),
					"modified": new_time,
					"settings": settings
				}
				save_dict(build_info_path, new_data)
		
		else:
			print(f"already up to date: {fname}")