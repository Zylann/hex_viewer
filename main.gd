extends Control

const Schema = preload("res://schema/schema.gd")
const SchemaMatcher = preload("res://schema/schema_matcher.gd")

export(Gradient) var gradient = null

onready var _text_view = $VB/HS/Main/ColorRect/VB/TextView
onready var _minimap = $VB/HS/Main/Minimap
onready var _status_label = $VB/StatusBar/Label
onready var _data_info = $VB/HS/TabContainer/QuickInfo/DataInfo
onready var _schema_editor = $VB/HS/TabContainer/Schema

# To avoid CoW
class BufferWrapper:
	var buffer = PoolByteArray()

var _wrapped_buffer := BufferWrapper.new()
var _open_dialog = null
var _filepath := ""
var _schema := Schema.new()
var _schema_matcher := SchemaMatcher.new()


func _ready():
	_text_view.set_wrapped_buffer(_wrapped_buffer)
	_data_info.set_wrapped_buffer(_wrapped_buffer)
	
	var base_control = self
	
	_open_dialog = FileDialog.new()
	_open_dialog.mode = FileDialog.MODE_OPEN_FILE
	_open_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_open_dialog.connect("file_selected", self, "_on_OpenDialog_file_selected")
	base_control.add_child(_open_dialog)
	
	_schema_editor.set_target_schema(_schema)
	_text_view.set_matcher_metadata(_schema_matcher.get_metadata_reference())
	
	# TEST
	#open_file("D:/PROJETS/INFO/GODOT/Plugins/HTerrain/hterrain/addons/zylann.hterrain/hterrain.gd")
	#open_file("D:/PROJETS/INFO/GODOT/Games/HexViewer/main.gd")
	#open_file("D:/PROJETS/INFO/GODOT/bin/Godot_v3.1-stable_win64.exe")
	#open_file("C:/Users/Marc/AppData/Roaming/.minecraft/saves/2b2t_org/region/r.0.0.mca")
	#open_file("D:/SONS/rus_battlecry11.wav")


func open_file(fpath: String):
	var f := File.new()
	var err := f.open(fpath, File.READ)
	if err != OK:
		printerr("Could not open ", fpath)
		return null
	OS.set_window_title(str(fpath, " - Hex Viewer"))
	var flen = f.get_len()
	var buffer = f.get_buffer(flen)
	f.close()
	_wrapped_buffer.buffer = buffer
	_minimap.update_textures(buffer)
	_text_view.update()
	_status_label.text = str(_format_number_with_commas(flen), " bytes")
	_filepath = fpath


static func _format_number_with_commas(n):
	assert(typeof(n) == TYPE_INT)
	assert(n >= 0)
	if n < 1000:
		return str(n)
	var s = str(n % 1000).pad_zeros(3)
	n /= 1000
	while true:
		if n < 1000:
			return str(str(n), ",", s)
		s = str(str(n % 1000).pad_zeros(3), ",", s)
		n /= 1000


func _on_OpenButton_pressed():
	_open_dialog.popup_centered_ratio()


func _on_OpenDialog_file_selected(fpath: String):
	open_file(fpath)


func _on_ReloadButton_pressed():
	if _filepath != "":
		open_file(_filepath)


func _on_Schema_schema_compiled():
	# TODO Custom root struct
	# TODO Custom start offset
	if _schema.is_empty():
		return
	var start_pos := 0
	if start_pos >= len(_wrapped_buffer.buffer):
		return
	var root_struct_name := "Data"
	_schema_matcher.run(_schema, _wrapped_buffer.buffer, root_struct_name, start_pos)


func _process(delta):
	if not _schema_matcher.is_finished():
		_schema_matcher.step()
		_text_view.update()
