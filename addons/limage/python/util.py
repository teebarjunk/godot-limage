import sys, os, json

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

def dict2str(data:dict) -> str:
	return json.dumps(data, separators=(',', ':'))

def file_size(path) -> str:
	return f"({nice_bytes(path.stat().st_size, 1)})"

def nice_bytes(size:int, precision:int=2) -> str:
	for suffix in ["b", "kb", "mb", "gb", "tp", "pb"]:
		if size > 1024:
			size /= 1024.0
		else:
			return f"{round(size, precision)} {suffix}"