extends Control

const Schema = preload("./schema.gd")
const SchemaParser = preload("res://schema/schema_parser.gd")

signal schema_compiled

const COMPILE_AFTER_EDIT_DELAY_SECONDS = 1.0

onready var _text_edit = $VB/TextEdit
onready var _error_label = $VB/ScrollContainer/ErrorLabel

var _time_before_compile := 0.0
var _schema : Schema


func _ready():
	var keyword_color = Color(1,0.2,0.1)
	var keywords = Schema.get_keywords()
	for keyword in keywords:
		_text_edit.add_keyword_color(keyword, keyword_color)
	
	_error_label.hide()


func set_target_schema(schema: Schema):
	_schema = schema


func _process(delta: float):
	if _time_before_compile > 0.0:
		_time_before_compile -= delta
		if _time_before_compile < 0.0:
			_compile()


func _on_TextEdit_text_changed():
	_time_before_compile = COMPILE_AFTER_EDIT_DELAY_SECONDS


func _compile():
	var parser = SchemaParser.new()
	var result = parser.parse(_text_edit.text)
	if result.schema == null:
		_error_label.text = str(result.error_line, ": ", result.error_message)
		_error_label.show()
		return
	_error_label.hide()
	_schema.clear()
	_schema.add_schema(result.schema)
	emit_signal("schema_compiled")
