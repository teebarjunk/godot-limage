from PIL import Image
from psd_tools import PSDImage
from psd_tools.constants import Tag
# from psd_tools.constants import BlendMode
import os, json, math, sys
import util, godot
from classes import Vec2

DEFAULT_SETTINGS:dict = {
	"path": "",						# location of psd
	"seperator": "-",				# change to "/" to folderize
	
	"texture_dir": None,			# if set, saves textures here
	"data_dir": "data",				# if set, saves layer data here
	# "script_dir": None,				# if set, saves godot scripts here
	
	# texture related
	"scale": 1,						# rescale textures
	"mask_scale": 1.0,#.25,				# shrink masks?
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

	"JPG": {
		"optimize": True,
		"quality": 80
	}
}
FORCE_UPDATE:bool = True if len(sys.argv) <= 1 else sys.argv[1] == "True"# True
SKIP_IMAGES:bool = False if len(sys.argv) <= 2 else sys.argv[2] == "True"#True
LOOK_IN:str = "layered_images"

print("args", sys.argv)

class PSDProcessor:
	def __init__(self, settings:dict):
		self.settings = settings
		self.update_image = True
		
		self.path = self.get("path", "")
		if self.path.startswith("res://"):
			self.path = self.path.replace("res://", util.DIR_RESOURCES)
		
		# filename without extension
		self.file_name = self.path.rsplit("/", 1)[1].rsplit(".", 1)[0]
	
	# settings
	def get(self, key:str, default=None):
		return util.get(self.settings, key, util.get(DEFAULT_SETTINGS, key, default))
	
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
	
	def load(self):
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
			l.visible = True#util.get(l._tags, "visible", True)
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
					print("set", child_origin.name, "origin to", child._origin)
		
		for l in list(all_layers):
			if l not in all_layers:
				continue
			
			# determine if this is a group
			l._is_group = l.kind == "group" and not "merge" in l._tags
			if l._is_group:
				# if merging, ignore lower data
				if "merge" in l._tags:
					for child in l.descendants():
						all_layers.remove(l)
				
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
	
	def save_data(self):
		
		
		if not self.data_dir:
			print("no 'data_dir' given. data won't be written to disk.")
			return
		
		# if self.structure == "tree":
			# collect children
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
		self.save_file(self.file_name, output)
	
	def save_file(self, file_name:str, data):
		# local_path = self.data_dir + "/" + file_name + ".tres"
		# path = util.DIR_RESOURCES + "/" + local_path
		# directory = path.rsplit("/", 1)[0]
		# util.create_directory(directory)
		
		json_text = json.dumps(data, indent=4)
		tres_text = godot.TEMPLATE_TRES + json_text
		
		# with open(path, "w") as file:
		# 	file.write(tres_text)
		
		self.save_string(tres_text, file_name, "tres")
		
		# godot script generator
		has_script, script = godot.generate_script(self.all_layers)
		if has_script:
			self.save_string(script, file_name.replace(" ", "_"), "gd")
			# local_path = self.data_dir + "/" + file_name.replace(" ", "_") + ".gd"
			# path = util.DIR_RESOURCES + "/" + local_path
			# with open(path, "w", encoding='utf-8') as f:
			# 	f.write(script)
		
	
	def save_string(self, string:str, name, extension, loud:bool=True):
		local_path = f"{self.data_dir}/{name}.{extension}"
		path = f"{util.DIR_RESOURCES}/{local_path}"
		directory = path.rsplit("/", 1)[0]
		util.create_directory(directory)
		
		with open(path, "w", encoding="utf-8") as file:
			file.write(string)
		
		if loud:
			print("saved:", local_path)
	
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
		
		# create directory.
		path = util.DIR_RESOURCES + "/" + local_path
		directory = path.rsplit("/", 1)[0]
		assert directory.startswith(util.DIR_RESOURCES), "path must be local"
		util.create_directory(directory)
		
		is_mask = "mask" in l._tags
		scale = self.scale if not is_mask else self.mask_scale
		
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
			
			image.save(path, self.format, **self.extension_settings)
			print("created texture:", local_path)
			
		l._scale = scale
		l._texture = "res://" + local_path
		self.texture_paths.append(local_path)
		
		# generate polygon
		if "poly" in l._tags:
			import genpoly
			points = genpoly.get_points(path, l._texture)
			self.save_string(points, f"poly_{self.name}", "tscn")
			print(points)


d = f"{util.DIR_RESOURCES}/{LOOK_IN}"

if os.path.exists(d):
	for file in os.listdir(d):
		if file.endswith(".psd"):
			
			fname, fextension = file.rsplit(".", 1)
			fpath = os.path.join(d, file)
			
			data_path = os.path.join(d, ".lim_" + fname + ".json")
			old_data = util.load_data(data_path, {})
			new_time = util.file_time(fpath)
			
			settings_path = os.path.join(d, fname + ".json")
			settings = util.load_data(settings_path, {})
			
			if FORCE_UPDATE or not "modified" in old_data or old_data["modified"] != new_time:
				settings["path"] = fpath
				
				PSDProcessor(settings).load()
				
				new_data = { "modified": new_time, "settings": settings }
				util.save_data(new_data, data_path)
			else:
				print("already up to date:", fname)

# s = {
# # "path": "/home/tee/Documents/psds/Female Sprite by Sutemo.psd",
# "path": "/home/tee/Documents/Krita/psds/door.psd",
# "texture_dir": "textures_gui",
# "data_dir": "textures_gui",
# "seperator": "-",
# # "origin": (0.5, 1.0)
# }
# s = {
# # "path": "/home/tee/Documents/psds/Female Sprite by Sutemo.psd",
# "path": "/home/tee/Documents/Krita/psds/items.psd",
# "texture_dir": "textures_items/icon",
# "data_dir": "textures_items/info",
# "seperator": "/",
# "structure": "solo",
# "scale": 0.25
# # "origin": (0.5, 1.0)
# }
# PSDProcessor(s).load()