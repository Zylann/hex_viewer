
const Token = preload("./schema_token.gd")

var _text : String
var _position := 0
var _error_message := ""
var _repushed_token = null
var _debug_tokens := []

const _operators = {
	"?": Token.QUESTION_MARK,
	"{": Token.BRACE_OPEN,
	"}": Token.BRACE_CLOSE,
	"[": Token.SQUARE_BRACKET_OPEN,
	"]": Token.SQUARE_BRACKET_CLOSE
}

const _keywords = {
	"if": Token.IF,
	"else": Token.ELSE
}


func _init(text: String):
	_text = text


func set_text(text: String):
	_text = text
	_error_message = ""
	_position = 0


func has_error() -> bool:
	return len(_error_message) > 0


func get_error_message() -> String:
	return _error_message


func get_line_number() -> int:
	return retrieve_line_number(_text, _position)


func get_position() -> int:
	return _position


func _make_error(message: String):
	_error_message = message


func get_next() -> Token:
	if _repushed_token != null:
		var token = _repushed_token
		_repushed_token = null
		return token
	var token = _get_next()
	_debug_tokens.append(token)
	return token


func repush_token(token: Token):
	assert(_repushed_token == null)
	_repushed_token = token


#func repush_token(token: Token):
#	assert(_repushed_token == null)
#	_repushed_token = token


func _get_next() -> Token:
	assert(not has_error())

#	if _repushed_token != null:
#		var token = _repushed_token
#		_repushed_token = null
#		return token
	
	while true:
		_position = _skip_whitespace(_text, _position)
		
		if _position >= len(_text):
			break
		
		var c : String = _text[_position]
		
		if c == "/":
			var pos = _position + 1
			if pos < len(_text) and _text[pos] == "/":
				# Comment
				while pos < len(_text):
					c = _text[pos]
					if c == "\n" or c == "\r":
						break
					pos += 1
				_position = pos
				continue
		
		if c == ";":
			# Allow but ignore them
			_position += 1
			continue
		
		if _operators.has(c):
			var token = Token.new()
			token.type = _operators[c]
			_position += 1
			return token
		
		if c == "-":
			var pos := _skip_whitespace(_text, _position)
			if pos >= len(_text):
				_make_error("Expected token after '-'")
				break

			c = _text[pos]

			if not c.is_valid_integer():
				var token = Token.new()
				token.type = Token.MINUS
				_position = pos
				return token
			
			return _parse_number(pos, true)
		
		if c.is_valid_integer():
			return _parse_number(_position, false)
		
		if c == "\"":
			# TODO Parse string
			pass
		
		if c.is_valid_identifier():
			var pos = _position + 1
			while pos < len(_text):
				c = _text[pos]
				if not (c.is_valid_identifier() or c.is_valid_integer()):
					break
				pos += 1
			var name = _text.substr(_position, pos - _position)
			_position = pos
			var token = Token.new()
			if _keywords.has(name):
				token.type = _keywords[name]
			else:
				token.type = Token.NAME
				token.value = name
			return token
		
		_make_error("Unexpected token")
		break
	
	return null


func _parse_number(number_pos: int, negative: bool) -> Token:
	var pos := number_pos
	while pos < len(_text):
		var c : String = _text[pos]
		if c.is_valid_integer() or c == ".":
			pos += 1
			continue
		break
	
	var number_text := _text.substr(number_pos, pos - number_pos)
	
	if number_text.is_valid_integer():
		var token = Token.new()
		token.type = Token.NUMBER_INT
		token.value = number_text.to_int()
		if negative:
			token.value = -token.value
		_position = pos
		return token
	
	if number_text.is_valid_float():
		var token = Token.new()
		token.type = Token.NUMBER_FLOAT
		token.value = number_text.to_float()
		if negative:
			token.value = -token.value
		_position = pos
		return token

	_make_error("Invalid number")
	return null


static func _skip_whitespace(s: String, from: int) -> int:
	var pos = from
	while pos < len(s):
		var c = s[pos]
		if c == " " or c == "\n" or c == "\r" or c == "\t":
			pos += 1
			continue
		return pos
	return pos


static func retrieve_line_number(s: String, pos: int) -> int:
	var line_number = 1
	for i in len(s):
		var c = s[i]
		if i == pos:
			break
		# TODO Handle different line endings
		if c == "\n":
			line_number += 1
	return line_number
