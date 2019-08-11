extends Control

export(DynamicFont) var font

var _row_width = 16
var _row_index = 0
var _wrapped_buffer = null
var _hex_to_string = []


func _ready():
	var hex = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
	for i in 256:
		_hex_to_string.append(str(hex[(i >> 4) & 0xf], hex[i & 0xf]))


func set_wrapped_buffer(b):
	_wrapped_buffer = b
	update()


func set_row_index(i):
	#print("Set row index ", i)
	assert(typeof(i) == TYPE_INT)
	if i != _row_index:
		_row_index = i
		update()


func get_row_index():
	return _row_index


func get_visible_row_count():
	var line_height = int(font.get_height())
	return int(rect_size.y) / line_height# + 1


func _draw():
	if _wrapped_buffer == null:
		return
	var buffer = _wrapped_buffer.buffer
	
	var begin_offset = _row_index * _row_width
	if begin_offset > len(buffer):
		return
	
	var line_height = int(font.get_height())
	var displayed_row_count = get_visible_row_count()
	var pos = Vector2(0, 0)
	
	var offset_text_width = 100
	var hex_text_width = 500
	
	var offset_color = Color(1, 1, 1, 0.5)
	var text_color = Color(1, 1, 1, 0.9)
	
	for i in displayed_row_count:
		var row_begin_offset = begin_offset + i * _row_width
		if row_begin_offset >= len(buffer):
			break
		
		var row_end_offset = row_begin_offset + _row_width
		if row_end_offset > len(buffer):
			row_end_offset = len(buffer)
		
		#draw_rect(Rect2(pos, Vector2(500, line_height)), bg_color)
		pos += Vector2(0, font.get_ascent())
		
		draw_string(font, pos, _offset_to_string(row_begin_offset), offset_color)
		pos.x += offset_text_width
		
		var hex_string = ""
		for j in range(row_begin_offset, row_end_offset):
			hex_string += str(_hex_to_string[buffer[j]], " ")
		draw_string(font, pos, hex_string, text_color)
		pos.x += hex_text_width
		var sub = buffer.subarray(row_begin_offset, row_end_offset - 1)
		for j in len(sub):
			var c = sub[j]
			if c < 32 or c >= 127:
				sub[j] = 46
		var ascii_string = sub.get_string_from_ascii()
		draw_string(font, pos, ascii_string, text_color)
		
		pos.x = 0
		pos.y -= font.get_ascent()
		pos.y += line_height


func _offset_to_string(offset):
	return str( \
		_hex_to_string[(offset >> 24) & 0xff], \
		_hex_to_string[(offset >> 16) & 0xff], \
		_hex_to_string[(offset >> 8) & 0xff], \
		_hex_to_string[offset & 0xff])


