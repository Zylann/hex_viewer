extends Control

export(Gradient) var gradient = null

onready var _text_view = get_node("VBoxContainer/HSplitContainer/Main/ColorRect/VBoxContainer/TextView")
onready var _minimap = get_node("VBoxContainer/HSplitContainer/Main/Minimap")
onready var _status_label = get_node("VBoxContainer/StatusBar/Label")
onready var _data_info = get_node("VBoxContainer/HSplitContainer/LeftPanel/DataInfo")

# To avoid CoW
class BufferWrapper:
	var buffer = PoolByteArray()

var _wrapped_buffer = BufferWrapper.new()
var _open_dialog = null
var _filepath = ""


func _ready():
	_text_view.set_wrapped_buffer(_wrapped_buffer)
	_data_info.set_wrapped_buffer(_wrapped_buffer)
	
	var base_control = self
	
	_open_dialog = FileDialog.new()
	_open_dialog.mode = FileDialog.MODE_OPEN_FILE
	_open_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_open_dialog.connect("file_selected", self, "_on_OpenDialog_file_selected")
	base_control.add_child(_open_dialog)


func open_file(fpath):
	var f = File.new()
	var err = f.open(fpath, File.READ)
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


func _on_OpenDialog_file_selected(fpath):
	open_file(fpath)


func _on_ReloadButton_pressed():
	if _filepath != "":
		open_file(_filepath)


