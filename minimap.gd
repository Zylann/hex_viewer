extends Control

signal ask_scroll(row_index)

onready var _overlay = get_node("Overlay")

var _images = []
var _textures = []
var _row_index = 0
var _strip_width = 16
var _strip_height = 4096
var _total_rows = 0
var _visible_rows_on_text = 20 # TODO Proper value


func update_textures(buffer):
	_images.clear()
	_textures.clear()
	
	_total_rows = len(buffer) / _strip_width + 1
	
	_images = _make_hex_images(buffer)
	
	var time_before = OS.get_ticks_msec()
	for im in _images:
		var tex = ImageTexture.new()
		tex.create_from_image(im, 0)
		_textures.append(tex)
	var time_spent = OS.get_ticks_msec() - time_before
	print("Spent ", time_spent, " ms uploading textures")
	
	update()
	_overlay.update()


func set_row_index(i):
	if _row_index != i:
		_row_index = i
		update()
		_overlay.update()


func _gui_input(event):
	if event is InputEventMouseMotion:
		if (event.button_mask & BUTTON_MASK_LEFT) != 0:
			var mpos = event.position
			var row_index = _get_row_index_from_visual_offset(mpos.y)
			emit_signal("ask_scroll", row_index)


func _draw():
	if len(_textures) == 0:
		return
	
	var visible_rows_on_map = int(rect_size.y)
	var ratio = _row_index / float(_total_rows)
	
	var virtual_map_offset = -int(ratio * (_total_rows - visible_rows_on_map + _visible_rows_on_text))

	var strip_index = -virtual_map_offset / _strip_height
	var total_strips = _total_rows / _strip_height + 1
	
	var map_offset = 0
	if _total_rows > visible_rows_on_map:
		map_offset = virtual_map_offset + _strip_height * strip_index
	#print(strip_index)
	
	_draw_strip(strip_index, map_offset)
	if strip_index + 1 < total_strips:
		_draw_strip(strip_index + 1, map_offset + _strip_height)
	

func _draw_strip(strip_index, y):
	var strips_per_page = _strip_height / _strip_width
	var page = strip_index / strips_per_page
	var tex = _textures[page]
	var src_rect = Rect2((strip_index % strips_per_page) * _strip_width, 0, _strip_width, tex.get_height())
	var dst_rect = Rect2(0, y, _strip_width, tex.get_height())
	draw_texture_rect_region(tex, dst_rect, src_rect)


func _on_Overlay_draw():
	var ci = _overlay
	var win_offset = _get_visual_offset_from_row_index(_row_index)
	var win_rect = Rect2(1, win_offset, rect_size.x - 1, _visible_rows_on_text)
	ci.draw_rect(win_rect, Color(1,1,1,0.3), true)
	ci.draw_rect(win_rect, Color(1,1,1,0.7), false)


func _get_visual_offset_from_row_index(row_index):
	if _total_rows <= rect_size.y:
		return row_index
	var ratio = _row_index / float(_total_rows)
	return ratio * (rect_size.y - _visible_rows_on_text)


func _get_row_index_from_visual_offset(y):
	if _total_rows <= rect_size.y:
		return int(y)
	var row_index = int(_total_rows * (y / rect_size.y)) - _visible_rows_on_text / 2
	return row_index


func _make_hex_images(buffer):
	var time_before = OS.get_ticks_msec()
	
	var strip_width = _strip_width
	var strip_height = _strip_height
	
	var strip_area = strip_width * strip_height
	var strip_count = buffer.size() / strip_area + 1
	print("Strip count: ", strip_count)
	
	var strip_count_per_atlas = strip_height / strip_width
	var atlas_count = strip_count / strip_count_per_atlas + 1
	print("Atlas count: ", atlas_count)
	
	var atlases = []
	
	for i in strip_count:
		#print("Building strip {0} / {1}".format([i, strip_count]))

		var im = Image.new()
		
		var begin_offset = i * strip_area
		var end_offset = begin_offset + strip_area
		
		if end_offset <= buffer.size():
			im.data = {
				"width": strip_width,
				"height": strip_height,
				"mipmaps": false,
				"format": "Red8",#Image.FORMAT_R8, # damnit
				"data": buffer.subarray(begin_offset, end_offset - 1)
			}
		else:
			im.create(strip_width, strip_height, false, Image.FORMAT_R8)
			im.fill(Color(0,0,0))
			end_offset = buffer.size()
			var span = end_offset - begin_offset
			im.lock()
			for j in span:
				var x = j % strip_width
				var y = j / strip_width
				var b = buffer[begin_offset + j]
				var f = b / 255.0
				im.set_pixel(x, y, Color(f, f, f))
			im.unlock()
		
		var atlas_index = i / strip_count_per_atlas
		var atlas
		if len(atlases) <= atlas_index:
			atlas = Image.new()
			atlas.create(strip_height, strip_height, false, Image.FORMAT_R8)
			atlases.append(atlas)
		else:
			atlas = atlases[-1]
		atlas.blit_rect(im, Rect2(0, 0, strip_width, strip_height), Vector2(strip_width * (i % strip_count_per_atlas), 0))
		
		# DEBUG
		#im.save_png(str("res://debug_data/strip_", i, ".png"))
	
	# DEBUG
#	for i in len(atlases):
#		atlases[i].save_png(str("res://debug_data/atlas_", i, ".png"))
#	for i in len(atlases):
#		var gradient = load("res://gradient.tres")
#		var im = atlases[i]
#		im = im.duplicate()
#		im.convert(Image.FORMAT_RGB8)
#		im.lock()
#		for y in im.get_height():
#			for x in im.get_width():
#				im.set_pixel(x, y, gradient.interpolate(im.get_pixel(x, y).r))
#			print("Grading ", y, "/", im.get_height())
#		im.unlock()
#		im.save_png(str("res://debug_data/atlas_", i, ".png"))
	
	var time_spent = OS.get_ticks_msec() - time_before
	print("Spent ", time_spent, " ms loading atlases")
	return atlases
