
class Structure:
	var name : String
	var items := []


class StructureItem:
	pass


class Field extends StructureItem:
	var id := -1
	var name : String
	var type_name : String
	# Can be string (refers to another field) or int (constant)
	var array_count
	var parent_struct_name : String
	var position_in_code := -1


class UnknownData extends StructureItem:
	pass


#class ConditionalItem extends StructureItem:
#	pass


const _FIELD_ID_START = 1


# [name] => Structure
var _structures := {}
# [field_id] => Field
var _fields := {}
var _next_field_id := _FIELD_ID_START

var _validated := false


const _primitive_types = {
	"u8": 1,
	"s8": 1,
	"u16": 2,
	"s16": 2,
	"u32": 4,
	"s32": 4,
	"f32": 4,
	"u64": 8,
	"s64": 8,
	"f64": 8
}

const _primitive_types_aliases = {
	# C#
	"byte": "u8",
	"sbyte": "s8",
	"short": "s16",
	"ushort": "u16",
	"int": "s32",
	"uint": "u32",
	"long": "s64",
	"ulong": "u64",
	"float": "f32",
	"double": "f64"
}


static func get_keywords() -> Array:
	var keywords = _primitive_types.keys()
	keywords.append_array(_primitive_types_aliases.keys())
	return keywords


static func is_primitive_type_name(type_name: String):
	return _primitive_types.has(type_name) or _primitive_types_aliases.has(type_name)


static func get_primitive_type_size(type_name: String) -> int:
	if not _primitive_types.has(type_name):
		type_name = _primitive_types_aliases[type_name]
	return _primitive_types[type_name]


func add_struct(struct: Structure):
	assert(len(struct.name) != 0)
	assert(not has_struct_name(struct.name))
	
	_structures[struct.name] = struct
	_validated = false
	
	for item in struct.items:
		if item is Field:
			item.id = _generate_field_id()
			item.parent_struct_name = struct.name
			_fields[item.id] = item


func is_empty() -> bool:
	return len(_structures) == 0


func _generate_field_id() -> int:
	var id = _next_field_id
	_next_field_id += 1
	return id


func get_structure_by_name(struct_name: String) -> Structure:
	return _structures[struct_name]


func has_struct_name(struct_name: String) -> bool:
	return _structures.has(struct_name)


func clear():
	_structures.clear()
	_fields.clear()
	_next_field_id = _FIELD_ID_START


func is_validated() -> bool:
	return _validated


# Note, `other` is not duplicated
func add_schema(other):
	assert(other.is_validated())
	for struct_name in other._structures:
		assert(not _structures.has(struct_name))
		add_struct(other._structures[struct_name])


class ValidateResult:
	var ok := false
	var error_message := ""
	var position_in_code := 0


func validate() -> ValidateResult:
	for struct_name in _structures:
		var struct : Structure = _structures[struct_name]

		for item_index in len(struct.items):
			var item = struct.items[item_index]

			if item is Field:
				if not is_primitive_type_name(item.type_name):
					if not _structures.has(item.type_name):
						var result = ValidateResult.new()
						result.ok = false
						result.error_message = "Unknown type name"
						result.position_in_code = item.position_in_code
						return result

				if typeof(item.array_count) == TYPE_STRING:
					var found = false

					for i in range(0, item_index):
						var preceding_item = struct.items[i]
						if preceding_item is Field and preceding_item.name == item.array_count:
							found = true
							break

					if not found:
						var result = ValidateResult.new()
						result.ok = false
						result.error_message = "Preceding field not found"
						result.position_in_code = item.position_in_code
						return result
	
	_validated = true
	
	var result := ValidateResult.new()
	result.ok = true
	return result
