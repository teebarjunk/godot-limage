import sys, os, json

DIR_RESOURCES: str = "/".join(sys.argv[0].split("/")[:-4])

_print = print
indent = 0
def custom_print(*args):
	_print("\t" * indent + " ".join([str(x) for x in args]))

def get(data:dict, key:str, default:object = None):
	return default if key not in data else data[key]

def str_to_obj(s:str) -> object:
	try:
		return float(s)
	except:
		try:
			return int(s)
		except:
			l = s.lower()
			if l == "true": return True
			if l == "false": return False
			return s

def get_between(name:str, tag1="[", tag2="]"):
	s = name.find(tag1)
	e = name.find(tag2, s+len(tag1))
	data = {}
	if s != -1 and e != -1:
		inner = name[s+len(tag1):e]
		# print(f"INNER: [{inner}]")
		
		# Replace spaces between quotes, for a second
		while True:
			qs = inner.find('"')
			qe = inner.find('"', qs+1)
			if qs != -1 and qe != -1:
				q0 = inner[:qs]
				q = inner[qs+1:qe]
				qn = inner[qe+1:]
				inner = q0 + q.replace(" ", "####") + qn
			else:
				break
		
		name = name.replace(f"{tag1}{inner}{tag2}", "")#name[:s].strip() + name[e+len(tag2):]
		inner = inner.split(" ")
		for key in inner:
			if "=" in key:
				key, val = key.split("=")
				# Return spaces to quotes.
				val = val.replace("####", " ").strip()
				data[key] = str_to_obj(val)
			else:
				data[key] = True
	return name, data


def parse_name(name:str) -> tuple:
	name, descendants_data = get_between(name, "((", "))")
	name, child_data = get_between(name, "(", ")")
	name, data = get_between(name, "[", "]")
	
	# sanitize name
	output = ""
	for c in name:
		if c in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_ ":
			output += c
	output = output.strip()
	
	# make safe
	if False:
		name = name.lower().replace(" ", "_")
	
	# print(output, data, child_data, descendants_data)
	return output, data, child_data, descendants_data


def create_directory(directory:str):
	if not os.path.exists(directory) and directory.startswith(DIR_RESOURCES):
		custom_print(f"creating directory: {directory}")
		os.makedirs(directory, exist_ok=True)


def dict2str(data:dict) -> str:
	return json.dumps(data, separators=(',', ':'))


def save_data(data:dict, path:str, indent:bool=True, log:bool=False):
	assert path.startswith(DIR_RESOURCES), "path must be local"
		
	directory = path.rsplit("/", 1)[0]
	create_directory(directory)
	
	with open(path, "w") as file:
		# JSON
		if path.endswith(".json"):
			if indent:
				json.dump(data, file, indent=4)
			else:
				json.dump(data, file, separators=(',', ':'))
		
		# YAML
		# elif path.endswith(".yaml"):
		# 	yaml.dump(data, file, default_flow_style=False, default_style='')
		
		# Godot Resource
		elif path.endswith(".tres"):
			d = dict2str(data)
			d = TEMPLATE_TRES.replace("%DATA%", d)
			file.write(d)
	
	if log:
		name = file_name(path)
		space = " " * (20 - len(name))
		size = file_size(path)
		custom_print(f"{name}{space}{size}")


def get_filepaths(directory:str, ext:str) -> list:
	file_paths = []
	for root, dirs, files in os.walk(directory):
		# Ignore hidden directories.
		dirs[:] = [d for d in dirs if not d.startswith(".")]
		for filename in files:
			if filename.endswith(ext):
				filepath = os.path.join(root, filename)
				file_paths.append(filepath)
	file_paths = sorted(file_paths, key=lambda file: (os.path.dirname(file), os.path.basename(file)))
	return file_paths


def file_name(path:str) -> str:
	return path.rsplit("/", 1)[1].split(".", 1)[0]

def file_size(path:str) -> str:
	return f"({nice_bytes(os.path.getsize(path), 1)})"

def file_time(path:str) -> str:
	return str(os.stat(path).st_mtime)

def localize_path(path:str, head:str="") -> str:
	output = path.replace(DIR_RESOURCES, head)
	if output[0] == "/":
		return output[1:]
	return output


def load_data(path:list, default:object = None) -> object:
	# Will attempt each path one at a time, returning first sucessfull.
	if os.path.exists(path):
		try:
			with open(path, "r") as file:
				# YAML
				# if path.endswith(".yaml"):
				# 	return list(yaml.safe_load_all(file))
				
				# JSON
				if path.endswith(".json"):
					return json.load(file)
		except Exception as e:
			custom_print(f"ERROR in {file_name(path)}: {e}")
	return default


def nice_bytes(size:int, precision:int=2) -> str:
	for suffix in ["b", "kb", "mb", "gb", "tp", "pb"]:
		if size > 1024:
			size /= 1024.0
		else:
			return f"{round(size, precision)} {suffix}"