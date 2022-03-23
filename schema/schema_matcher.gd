
const Schema = preload("./schema.gd")

class Metadata:
	# Fuck pool arrays
	#var field_ids := PoolIntArray()
	# Let's waste memory instead
	
	# Byte index => ID of the field in the Schema
	var field_ids = []


class StackFrame:
	# Which struct are we in
	var struct
	# Which item of the struct are we evaluating
	var item_index := 0
	# Field name => value (when a primitive)
	var referred_field_values := {}


var _binary_data : PoolByteArray

# 1 item per byte
# TODO Optimize
var _position := 0
var _schema : Schema
# Array of StackFrame
var _stack = []
var _metadata := Metadata.new()
var _end = true


func run(schema: Schema, binary_data: PoolByteArray, root_struct_name: String, start_position: int):
	# No clear() method in pool arrays??
	_position = start_position
	_binary_data = binary_data
	assert(_position < len(_binary_data))
	_schema = schema

	_stack.clear()
	var stack_frame = StackFrame.new()
	stack_frame.struct = schema.get_structure_by_name(root_struct_name)
	stack_frame.item_index = 0
	_stack.append(stack_frame)

	_metadata.field_ids = []#PoolIntArray()
	
	if len(stack_frame.struct.items) > 0:
		_end = false
	else:
		_end = true


func is_finished() -> bool:
	return _end


func get_metadata_reference() -> Metadata:
	return _metadata


func step():
	assert(not _end)
	
	if _position >= len(_binary_data):
		_end = true
		return
	
	var stack_frame = _stack[len(_stack) - 1]
	var struct : Schema.Structure = stack_frame.struct
	var item = struct.items[stack_frame.item_index]

	if item is Schema.Field:
		var array_count := 1
		if typeof(item.array_count) == TYPE_INT:
			array_count = item.array_count
		elif typeof(item.array_count) == TYPE_STRING:
			array_count = stack_frame.referred_field_values[item.array_count]
		elif typeof(item.array_count) == TYPE_NIL:
			pass
		else:
			# Unexpected type
			assert(false)
		assert(typeof(array_count) == TYPE_INT)

		if Schema.is_primitive_type_name(item.type_name):
			var size = Schema.get_primitive_type_size(item.type_name) * array_count

			if item.referred and Schema.is_integer_primitive_type_name(item.type_name) \
			and _position + size <= len(_binary_data):
				var n = _read_uint(_binary_data, _position, size)
				stack_frame.referred_field_values[item.name] = n

			#print("Array count: ", array_count)
			for i in size:
				_metadata.field_ids.append(item.id)
			_position += size
			stack_frame.item_index += 1

		else:
			stack_frame.item_index += 1
			
			var sub_struct = _schema.get_structure_by_name(item.type_name)
			
			var sub_stack_frame := StackFrame.new()
			sub_stack_frame.struct = sub_struct
			sub_stack_frame.item_index = 0
			_stack.push_back(sub_stack_frame)

	elif item is Schema.UnknownData:
		_end = true
	
	else:
		# TODO Handle conditionals etc
		assert(false)
	
	var last_stack_frame = _stack[len(_stack) - 1]
	if last_stack_frame.item_index == len(last_stack_frame.struct.items):
		_stack.pop_back()
		if len(_stack) == 0:
			_end = true


static func _read_uint(binary_data, begin: int, length: int) -> int:
	var n = 0
	for i in length:
		n = (n << 8) | binary_data[begin + i]
#	if signed and ((n >> (length * 8 - 1)) & 1) != 0:
#		n = -n
	return n

