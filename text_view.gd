extends Control

const SchemaMatcher = preload("res://schema/schema_matcher.gd")

export(DynamicFont) var font : DynamicFont

signal hovered_offset_changed(offset)

onready var _bg = get_node("Bg")

var _row_width := 16
var _row_index := 0
var _wrapped_buffer = null
var _hex_to_string := []
var _char_width := 0
var _offset_gutter_width := 0
var _hex_gutter_width := 0
var _ascii_gutter_width := 0
var _gutter_separation := 0
# Visual
var _hovered_row := -1
var _hovered_col := -1

var _metadata : SchemaMatcher.Metadata
var _hovered_metadata_begin := -1
var _hovered_metadata_end := -1


func _ready():
	var hex = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
	for i in 256:
		_hex_to_string.append(str(hex[(i >> 4) & 0xf], hex[i & 0xf]))
	# Monospace font assumed
	var char_size = font.get_string_size("A")
	_char_width = int(char_size.x)
	_offset_gutter_width = _char_width * 8
	_hex_gutter_width =  _char_width * (3 * _row_width - 1)
	_ascii_gutter_width = _char_width * _row_width
	_gutter_separation = _char_width * 2


func set_wrapped_buffer(b):
	_wrapped_buffer = b
	update()


func set_matcher_metadata(meta: SchemaMatcher.Metadata):
	_metadata = meta


func set_row_index(i):
	#print("Set row index ", i)
	assert(typeof(i) == TYPE_INT)
	if i != _row_index:
		_row_index = i
		_set_hovered_row_col_from_mouse(get_local_mouse_position())
		update()


func get_row_index():
	return _row_index


func get_visible_row_count() -> int:
	var line_height = int(font.get_height())
	return int(rect_size.y) / line_height# + 1


func _gui_input(event):
	if event is InputEventMouseMotion:
		_set_hovered_row_col_from_mouse(event.position)


func _set_hovered_row_col_from_mouse(mpos):
	var rowcol = _get_row_col_from_mouse_pos(mpos)
	if rowcol == null:
		_set_hovered_row_col(-1, -1)
	else:
		_set_hovered_row_col(rowcol[0], rowcol[1])


func _get_hovered_offset() -> int:
	if _hovered_col == -1 or _hovered_row == -1:
		return -1
	return _hovered_col + _hovered_row * _row_width


func _set_hovered_row_col(row: int, col: int):
	var prev_offset := _get_hovered_offset()
	
	if row != _hovered_row or col != _hovered_col:
		#print("Hover ", row, ", ", col)
		_hovered_row = row
		_hovered_col = col
		
		_bg.update()

	var offset = _get_hovered_offset()
	
	if offset != prev_offset:
		var meta_begin_offset := -1
		var meta_end_offset := -1
		
		if offset != -1:
			emit_signal("hovered_offset_changed", offset)
		
			var ra := _get_metadata_range(offset)
			meta_begin_offset = ra[0]
			meta_end_offset = ra[1]

		if meta_begin_offset != _hovered_metadata_begin \
		or meta_end_offset != _hovered_metadata_end:
			# TODO Separate matcher highlighting?
			update()
		
		_hovered_metadata_begin = meta_begin_offset
		_hovered_metadata_end = meta_end_offset


func _get_metadata_range(p_offset: int) -> Array:
	if _metadata == null or p_offset >= len(_metadata.field_ids):
		return [-1, -1]

	var field_id : int = _metadata.field_ids[p_offset]

	var begin_offset = p_offset
	while begin_offset > 0 and _metadata.field_ids[begin_offset - 1] == field_id:
		begin_offset -= 1

	var end_offset = p_offset
	while end_offset < len(_metadata.field_ids) and _metadata.field_ids[end_offset] == field_id:
		end_offset += 1
	
	return [begin_offset, end_offset]


func _get_row_col_from_mouse_pos(mpos):
	var hex_gutter_begin = _offset_gutter_width + _gutter_separation
	var hex_gutter_end = hex_gutter_begin + _hex_gutter_width
	
	var ascii_gutter_begin = hex_gutter_end + _gutter_separation
	var ascii_gutter_end = ascii_gutter_begin + _ascii_gutter_width
	
	var visual_rowcol
	
	if mpos.x >= hex_gutter_begin and mpos.x < hex_gutter_end:
		mpos.x -= hex_gutter_begin
		visual_rowcol = (mpos / Vector2(3 * _char_width, font.get_height())).floor()
	
	elif mpos.x >= ascii_gutter_begin and mpos.x < ascii_gutter_end:
		mpos.x -= ascii_gutter_begin
		visual_rowcol = (mpos / Vector2(_char_width, font.get_height())).floor()
	
	if visual_rowcol != null:
		# Use integers because row can be a high number, floats would ruin it
		return [int(visual_rowcol.y) + _row_index, int(visual_rowcol.x)]
	return null


func _draw():
	if _wrapped_buffer == null:
		return
	var buffer : PoolByteArray = _wrapped_buffer.buffer
	
	var begin_offset := _row_index * _row_width
	if begin_offset > len(buffer):
		return
	
	var line_height := int(font.get_height())
	var displayed_row_count := get_visible_row_count()
	var pos := Vector2(0, 0)

	#var hex_text_width = 500
	
	var offset_color = Color(1, 1, 1, 0.5)
	var text_color = Color(1, 1, 1, 0.9)
	var zero_color = Color(1, 1, 1, 0.5)
	
	if _metadata != null:
		_draw_matcher_background(displayed_row_count, begin_offset, buffer)
	
	for visual_row_index in displayed_row_count:
		var row_begin_offset : int = begin_offset + visual_row_index * _row_width
		if row_begin_offset >= len(buffer):
			break
		
		var row_end_offset = row_begin_offset + _row_width
		if row_end_offset > len(buffer):
			row_end_offset = len(buffer)
		
		#draw_rect(Rect2(pos, Vector2(500, line_height)), bg_color)
		pos += Vector2(0, font.get_ascent())
		
		# Offset
		
		draw_string(font, pos, _offset_to_string(row_begin_offset), offset_color)
		pos.x += _offset_gutter_width + _gutter_separation
		
		# Hex view
				
		var hex_string = ""
		var zero_string = ""
		for j in range(row_begin_offset, row_end_offset):
			var b = buffer[j]
			if b == 0:
				zero_string += str(_hex_to_string[b], " ")
				hex_string += "   "
			else:
				zero_string += "   "
				hex_string += str(_hex_to_string[buffer[j]], " ")
		draw_string(font, pos, hex_string, text_color)
		draw_string(font, pos, zero_string, zero_color)
		pos.x += _hex_gutter_width + _gutter_separation
		
		# ASCII view
		
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


func _draw_matcher_background(displayed_row_count: int, begin_offset: int, buffer: PoolByteArray):
	var pos := Vector2(_offset_gutter_width + _gutter_separation, 0)
	
	var visual_byte_size := Vector2(_char_width * 3, font.get_height())
	
	for visual_row_index in displayed_row_count:
		var row_begin_offset : int = begin_offset + visual_row_index * _row_width
		if row_begin_offset >= len(buffer):
			break
		
		var row_end_offset = row_begin_offset + _row_width
		if row_end_offset > len(buffer):
			row_end_offset = len(buffer)
		
		if row_begin_offset < len(_metadata.field_ids):
			_draw_matcher_background_row(row_begin_offset, row_end_offset, pos, visual_byte_size)
		else:
			break
		
		pos.y += font.get_height()


func _draw_matcher_background_row(row_begin_offset: int, row_end_offset: int, pos: Vector2, 
	visual_byte_size: Vector2):
	
	var start := row_begin_offset
	var prev_field_id : int = _metadata.field_ids[row_begin_offset]
	
	for j in range(row_begin_offset + 1, row_end_offset):
		var field_id := -1
		if j < len(_metadata.field_ids):
			field_id = _metadata.field_ids[j]
		
		var w := 0
		if field_id != prev_field_id:
			w = j - start
		elif j + 1 == row_end_offset:
			w = j - start + 1
		if w > 0:
			var bg_rect := Rect2(pos, Vector2(visual_byte_size.x * w, visual_byte_size.y))
			var color := Color(0,0.2,0)
			if start >= _hovered_metadata_begin and j <= _hovered_metadata_end:
				color = Color(0,0.4,0)
			draw_rect(bg_rect.grow(-1), color)
			pos.x += bg_rect.size.x

			start = j
			
			if field_id == -1:
				break
		
		prev_field_id = field_id


func _offset_to_string(offset):
	return str( \
		_hex_to_string[(offset >> 24) & 0xff], \
		_hex_to_string[(offset >> 16) & 0xff], \
		_hex_to_string[(offset >> 8) & 0xff], \
		_hex_to_string[offset & 0xff])


func _on_Bg_draw():
	if _hovered_col == -1 or _hovered_row == -1:
		return
	var ci = _bg
	
	var visual_row = _hovered_row - _row_index

	var hex_gutter_begin = _offset_gutter_width + _gutter_separation
	var ascii_gutter_begin = hex_gutter_begin + _hex_gutter_width + _gutter_separation
	
	var hcsize = Vector2(3.0 * _char_width, font.get_height())
	var hpos = Vector2(_hovered_col, visual_row) * hcsize

	var acsize = Vector2(_char_width, font.get_height())
	var apos = Vector2(_hovered_col, visual_row) * acsize
	
	var col = Color(1,1,1,0.06)
	ci.draw_rect(Rect2(hex_gutter_begin + hpos.x, 0, hcsize.x, rect_size.y), col)
	ci.draw_rect(Rect2(hex_gutter_begin, hpos.y, _hex_gutter_width, hcsize.y), col)

	ci.draw_rect(Rect2(ascii_gutter_begin + apos.x, 0, acsize.x, rect_size.y), col)
	ci.draw_rect(Rect2(ascii_gutter_begin, apos.y, _ascii_gutter_width, acsize.y), col)

