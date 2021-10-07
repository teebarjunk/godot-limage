
## ToolButtonPlugin for Godot - v1.0

Add inspector buttons to any script with one function.

![ReadMe](readme/preview.png "Preview")

## Start

- Enable plugin.
- Add **tool** to top of your script.
- Add func **_get_tool_buttons** that returns names of functions.


## Simple Example

```gd
tool
extends Node

func _get_tool_buttons(): return ["my_function"]

func my_function():
    print("I was called!")
```

## Advanced Example

Using *Dictionary*s instead of *String*s.

*call* is mandatory. Other's are optional.

|key    |desc                           |default              |
|:------|:------------------------------|:--------------------|
|call   | Method to call                | - |
|args   | Array of arguments to pass    | - |
|text   | Button label                  | - |
|tint   | Button color                  | Color.white |
|icon   | Button icon                   | -
|flat   | Button is flat style          | false |
|hint   | Hint text for mouse over      | - |
|print  | Print output of method call?  | false |
|align  | Button alignment              | Button.ALIGN_CENTER |
|disable| Disable button?               | false |

```gd
var _direction:String = ""
var _score:int = 0

func _get_tool_buttons():
    return [{
        call="go_towards",
        args=["West"]
    },{
        call="go_towards",
        args=["East", true],
        text="Bad Move",
        tint=Color.red,
    }]

func go_towards(direction:String, bad_action:bool=false):
    _direction = direction
    
    if bad_action:
        _score -= 10
    
    return _score
```

## More Advanced Example

Showing optional buttons by using Godot's **property_list_changed_notify** to force update.

```gd
tool
extends Node

export(bool) var show_score_button:bool = false setget set_show_score_button
export(int) var score:int = 0

func set_show_score_button(value):
	show_score_button = value
	property_list_changed_notify() # force property list to "redraw"

func _get_tool_buttons():
    var out = []
	if show_score_button:
        # hidden unless show_score_button is enabled
		out.append({call="add_score", args=[10], disable=score>100, tint=Color.aqua})
	return out

func add_score(amount:int):
	self.score += amount
	property_list_changed_notify() # force property list to "redraw"

```
