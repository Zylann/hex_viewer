
const Schema = preload("./schema.gd")
const Tokenizer = preload("./schema_tokenizer.gd")
const Token = preload("./schema_token.gd")

const _FIELD_RETURN_END_OF_STRUCT = 0
const _FIELD_RETURN_END_OF_LINE = 1
const _FIELD_RETURN_ERROR = 2

class Result:
	const Schema = preload("./schema.gd")
	
	var schema : Schema
	var error_message : String
	var error_line := -1


var _error_message := ""


func _has_error() -> bool:
	return len(_error_message) > 0


func _make_error(message: String):
	_error_message = message


func parse(text: String) -> Result:
	var tokenizer := Tokenizer.new(text)
	var schema := Schema.new()
	
	while true:
		if _has_error() or tokenizer.has_error():
			break
		
		var token := tokenizer.get_next()
		if token == null:
			break
		
		if token.type == Token.NAME:
			_parse_struct(tokenizer, schema, token.value)
			continue
		
		# TODO Token stringification
		_make_error(str("Unexpected token (", token.type, ")"))
		break
			
	var result := Result.new()
	
	if tokenizer.has_error():
		result.error_message = tokenizer.get_error_message()
		result.error_line = tokenizer.get_line_number()
	
	elif _has_error():
		result.error_message = _error_message
		result.error_line = tokenizer.get_line_number()
	
	else:
		var validation_result = schema.validate()
		if not validation_result.ok:
			result.error_message = validation_result.error_message
			result.error_line = \
				Tokenizer.retrieve_line_number(text, validation_result.position_in_code)
		else:
			result.schema = schema
	
	return result


func _parse_struct(tokenizer: Tokenizer, schema: Schema, name: String):
	assert(len(name) > 0)

	if schema.has_struct_name(name):
		_make_error("Duplicate structure definition")
		return
	
	var token := tokenizer.get_next()
	if token.type != Token.BRACE_OPEN:
		_make_error("Expected '{' token")
		return

	var struct = Schema.Structure.new()
	struct.name = name
	
	while true:
		if _has_error() or tokenizer.has_error():
			return
		
		token = tokenizer.get_next()
		if token == null:
			_make_error("Unexpected end of file")
			return
		
		if token.type == Token.IF:
			_make_error("Conditionals not supported yet")
			# TODO Support conditionals
			return
		
		if token.type == Token.NAME:
			var ret = _parse_field(tokenizer, struct, token.value)
			if ret == _FIELD_RETURN_END_OF_STRUCT:
				break
			continue
		
		if token.type == Token.QUESTION_MARK:
			struct.items.append(Schema.UnknownData.new())
			continue
		
		if token.type == Token.BRACE_CLOSE:
			break
		
		_make_error("Unexpected token")
		return
	
	schema.add_struct(struct)


func _parse_field(tokenizer: Tokenizer, struct: Schema.Structure, type_name: String) -> int:
	var field = Schema.Field.new()
	field.type_name = type_name
	field.position_in_code = tokenizer.get_position()
	
	var token := tokenizer.get_next()
	
	var has_array_count = false
	if token.type == Token.SQUARE_BRACKET_OPEN:
		if not _parse_array_count(tokenizer, field):
			return _FIELD_RETURN_ERROR
		has_array_count = true
	
	if token.type != Token.NAME:
		_make_error("Expected field name")
		return _FIELD_RETURN_ERROR
	
	field.name = token.value
	
	token = tokenizer.get_next()
	
	var ret = _FIELD_RETURN_END_OF_LINE
	
	if token.type == Token.SQUARE_BRACKET_OPEN:
		if has_array_count:
			_make_error("Array count already specified")
			return _FIELD_RETURN_ERROR
		if not _parse_array_count(tokenizer, field):
			return _FIELD_RETURN_ERROR

	elif token.type == Token.BRACE_CLOSE:
		ret = _FIELD_RETURN_END_OF_STRUCT
	
	# Note, semicolons are ignored by the parser
	
	struct.items.append(field)

	return ret


func _parse_array_count(tokenizer: Tokenizer, field: Schema.Field) -> bool:
	var token := tokenizer.get_next()

	if tokenizer.has_error():
		return false
	if token == null:
		_make_error("Unexpected end of file")
		return false

	if token.type == Token.NUMBER_INT:
		if token.value <= 0:
			_make_error("Invalid array count")
			return false
		field.array_count = token.value

	elif token.type == Token.NAME:
		field.array_count = token.name
	
	else:
		_make_error("Expected positive integer or field name")
		return false

	token = tokenizer.get_next()
	if tokenizer.has_error():
		return false
	if token == null:
		_make_error("Unexpected end of file")
		return false

	if token.type != Token.SQUARE_BRACKET_CLOSE:
		_make_error("Expected ']'")
		return false
	
	return true
