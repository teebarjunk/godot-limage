tool
extends LimageNode

export(String, "default", "happy", "sus", "angry") var _expression:String = "default" setget set_expression, get_expression
export(String, "white", "blue", "suit") var _shirt:String = "blue" setget set_shirt, get_shirt
export(bool) var _worn_sunglasses:bool = false setget set_worn_sunglasses, get_worn_sunglasses
export(bool) var _worn_hat:bool = true setget set_worn_hat, get_worn_hat
export(bool) var _worn_chain:bool = false setget set_worn_chain, get_worn_chain
export(bool) var _worn_chain2:bool = false setget set_worn_chain2, get_worn_chain2
export(bool) var _worn_beard:bool = false setget set_worn_beard, get_worn_beard

func get_expression() -> String: return get_option("expression")
func set_expression(v:String):
	_expression = v
	set_option("expression", v)

func get_shirt() -> String: return get_option("shirt")
func set_shirt(v:String):
	_shirt = v
	set_option("shirt", v)

func get_worn_sunglasses() -> bool: return get_toggle("worn/sunglasses")
func set_worn_sunglasses(v:bool):
	_worn_sunglasses = v
	set_toggle("worn/sunglasses", v)

func get_worn_hat() -> bool: return get_toggle("worn/hat")
func set_worn_hat(v:bool):
	_worn_hat = v
	set_toggle("worn/hat", v)

func get_worn_chain() -> bool: return get_toggle("worn/chain")
func set_worn_chain(v:bool):
	_worn_chain = v
	set_toggle("worn/chain", v)

func get_worn_chain2() -> bool: return get_toggle("worn/chain2")
func set_worn_chain2(v:bool):
	_worn_chain2 = v
	set_toggle("worn/chain2", v)

func get_worn_beard() -> bool: return get_toggle("worn/beard")
func set_worn_beard(v:bool):
	_worn_beard = v
	set_toggle("worn/beard", v)

