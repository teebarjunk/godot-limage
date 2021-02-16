class Vec2(dict):
	def __init__(self, x:float=0, y:float=0):
		if isinstance(x, (tuple, list)):
			self.x, self.y = x[0], x[1]
		elif isinstance(x, dict):
			self.x, self.y = x["x"], x["y"]
		elif isinstance(x, (float, int)):
			self.x, self.y = x, y
		else:
			print("VEC2 ERROR!")
	
	@property
	def x(self):
		return self["x"]
	
	@property
	def y(self):
		return self["y"]

	@x.setter
	def x(self, x):
		self["x"] = x
	
	@y.setter
	def y(self, y):
		self["y"] = y
	
	def __add__(self, obj):
		if isinstance(obj, (float, int)):
			return Vec2(self.x + obj, self.y + obj)
		elif isinstance(obj, (tuple, list)):
			return Vec2(self.x + obj[0], self.y + obj[1])
		elif isinstance(obj, dict):
			return Vec2(self.x + obj["x"], self.y + obj["y"])
		else:
			return Vec2(self.x + obj.x, self.y + obj.y)
	
	def __sub__(self, obj):
		if isinstance(obj, (float, int)):
			return Vec2(self.x - obj, self.y - obj)
		elif isinstance(obj, (tuple, list)):
			return Vec2(self.x - obj[0], self.y - obj[1])
		elif isinstance(obj, dict):
			return Vec2(self.x - obj["x"], self.y - obj["y"])
		else:
			return Vec2(self.x - obj.x, self.y - obj.y)
	
	def __mul__(self, obj):
		if isinstance(obj, (float, int)):
			return Vec2(self.x * obj, self.y * obj)
		elif isinstance(obj, (tuple, list)):
			return Vec2(self.x * obj[0], self.y * obj[1])
		elif isinstance(obj, dict):
			return Vec2(self.x * obj["x"], self.y * obj["y"])
		else:
			return Vec2(self.x * obj.x, self.y * obj.y)
	
	def negative(self):
		return Vec2(-self.x, -self.y)
	
	def copy(self):
		return Vec2(self.x, self.y)