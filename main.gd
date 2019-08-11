extends Control

export(Gradient) var gradient = null

onready var _text_view = get_node("VBoxContainer/Main/ColorRect/TextView")
onready var _minimap = get_node("VBoxContainer/Main/Minimap")

# To avoid CoW
class BufferWrapper:
	var buffer = PoolByteArray()

var _colors = []
var _images = []
var _wrapped_buffer = BufferWrapper.new()


func _ready():
	_text_view.set_wrapped_buffer(_wrapped_buffer)
	for i in 256:
		var col = gradient.interpolate(i / 256.0)
		_colors.append(col)
	#open_file("D:/PROJETS/INFO/GODOT/Plugins/HTerrain/hterrain/addons/zylann.hterrain/hterrain.gd")
	#open_file("D:/PROJETS/INFO/GODOT/Games/HexViewer/main.gd")
	open_file("D:/PROJETS/INFO/GODOT/bin/Godot_v3.1-stable_win64.exe")
	#open_file("C:/Users/Marc/AppData/Roaming/.minecraft/saves/2b2t_org/region/r.0.0.mca")
	#open_file("D:/SONS/rus_battlecry11.wav")


func open_file(fpath):
	var f = File.new()
	var err = f.open(fpath, File.READ)
	if err != OK:
		printerr("Could not open ", fpath)
		return null
	var flen = f.get_len()
	var buffer = f.get_buffer(flen)
	f.close()
	_wrapped_buffer.buffer = buffer
	_minimap.update_textures(buffer)
	_text_view.update()

