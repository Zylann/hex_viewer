extends GridContainer

var _u8_label = null
var _u16_label = null
var _u32_label = null
# TODO Can't manipulate u64 in GDScript Oo

var _s8_label = null
var _s16_label = null
var _s32_label = null
var _s64_label = null

var _f32_label = null
var _f64_label = null

var _wrapped_buffer = null


func _ready():
	_add_spacer()
	
	_u8_label =  _add_labels("u8    ")
	_u16_label = _add_labels("u16   ")
	_u32_label = _add_labels("u32   ")
	
	_add_spacer()
	
	_s8_label =  _add_labels("s8    ")
	_s16_label = _add_labels("s16   ")
	_s32_label = _add_labels("s32   ")
	_s64_label = _add_labels("s64   ")

	_add_spacer()
	
	_f32_label = _add_labels("f32   ")
	_f64_label = _add_labels("f64   ")


func _add_labels(text1, text2 = "---"):
	_add_label(text1)
	return _add_label(text2)


func _add_label(text):
	var label = Label.new()
	label.text = text
	add_child(label)
	return label


func _add_spacer():
	var sp = Control.new()
	sp.rect_min_size = Vector2(0, 8)
	add_child(sp)
	add_child(Control.new())


func set_wrapped_buffer(wb):
	_wrapped_buffer = wb


func set_offset(offset):
	var buffer = _wrapped_buffer.buffer
	
	_u8_label.text = "---"
	_u16_label.text = "---"
	_u32_label.text = "---"
	
	_s8_label.text = "---"
	_s16_label.text = "---"
	_s32_label.text = "---"
	_s64_label.text = "---"
	
	_f32_label.text = "---"
	_f64_label.text = "---"

	if offset < 0 or offset >= len(buffer):
		return
		
	_u8_label.text = str(buffer[offset])
	
	var big_endian = false
	
	if big_endian:
		# TODO Big endian decoding
		pass
		
	else:
		if offset + 1 < len(buffer):
			_u16_label.text = str(_decode_u16(buffer, offset))
	
		if offset + 3 < len(buffer):
			_u32_label.text = str(_decode_u32(buffer, offset))

		if offset + 7 < len(buffer):
			_s64_label.text = str(_decode_s64(buffer, offset))
		
		# TODO Signed types
		# TODO Float types


func _decode_u8(buffer, offset):
	return buffer[offset]


func _decode_u16(buffer, offset):
	return (buffer[offset] << 8) | buffer[offset + 1]


func _decode_u32(buffer, offset):
	return (buffer[offset] << 24) | \
		(buffer[offset + 1] << 16) | \
		(buffer[offset + 2] << 8) | \
		buffer[offset + 3]


func _decode_s64(buffer, offset):
	return (buffer[offset] << 56) | \
		(buffer[offset + 1] << 48) | \
		(buffer[offset + 2] << 40) | \
		(buffer[offset + 3] << 32) | \
		(buffer[offset + 4] << 24) | \
		(buffer[offset + 5] << 16) | \
		(buffer[offset + 6] << 8) | \
		buffer[offset + 7]


func _on_TextView_hovered_offset_changed(offset):
	set_offset(offset)


