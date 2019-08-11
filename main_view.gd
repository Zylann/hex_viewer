extends HBoxContainer


onready var _text_view = get_node("ColorRect/TextView")
onready var _minimap = get_node("Minimap")

var _last_scroll_time = 0


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_WHEEL_DOWN:
					_scroll(int(event.factor))
				BUTTON_WHEEL_UP:
					_scroll(-int(event.factor))


func _scroll(delta):
	var now = OS.get_ticks_msec()
	if Input.is_key_pressed(KEY_CONTROL):
		var rc = _text_view.get_visible_row_count()
		if delta < 0:
			delta = -rc
		else:
			delta = rc
	elif now - _last_scroll_time < 20:
		delta *= 3
	elif now - _last_scroll_time < 50:
		delta *= 2
	_last_scroll_time = OS.get_ticks_msec()
	
	var i = _text_view.get_row_index() + delta
	if i < 0:
		i = 0
	_text_view.set_row_index(i)
	_minimap.set_row_index(i)

	