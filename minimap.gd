extends Control

var _images = []
var _textures = []
var _row_index = 0
var _strip_width = 16


func update_textures(buffer):
	_images.clear()
	_textures.clear()
	
	_images = _make_hex_images(buffer)
	
	var time_before = OS.get_ticks_msec()
	for im in _images:
		var tex = ImageTexture.new()
		tex.create_from_image(im, 0)
		_textures.append(tex)
	var time_spent = OS.get_ticks_msec() - time_before
	print("Spent ", time_spent, " ms uploading textures")
	
	update()


func set_row_index(i):
	if _row_index != i:
		_row_index = i
		update()


func _draw():
	if len(_textures) == 0:
		return
	# TODO
	var tex = _textures[0]
	var dst_rect = Rect2(0, 0, _strip_width, tex.get_height())
	var src_rect = Rect2(0, 0, _strip_width, tex.get_height())
	draw_texture_rect_region(tex, dst_rect, src_rect)


func _make_hex_images(buffer):
	var time_before = OS.get_ticks_msec()
	
	var strip_width = _strip_width
	var strip_height = 4096
	
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
	
	var time_spent = OS.get_ticks_msec()
	print("Spent ", time_spent, " ms loading atlases")
	return atlases


