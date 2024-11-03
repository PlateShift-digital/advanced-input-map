extends Node

enum FLAGS {
	SHIFT = 1,
	ALT = 2,
	CTRL = 4,
}

var key_map: Dictionary = {}
var groups: Dictionary = {}
var pressed: Dictionary = {}

var _enabled_groups: Array = []

var key_priority: Array = [
	# we dont need to check a combination of all 3 since that'd be a direct match.
	FLAGS.SHIFT | FLAGS.ALT,
	FLAGS.CTRL | FLAGS.SHIFT,
	FLAGS.CTRL | FLAGS.ALT,
	FLAGS.SHIFT,
	FLAGS.ALT,
	FLAGS.CTRL,
	# no need to check for no flags used, as it is the global fallback
]


#region: internals
func _ready() -> void:
	var group_data: Dictionary = load_groups()
	var input_map_data: Dictionary = load_configuration()

	for group in load_groups():
		groups[group] = group_data[group].enabled
		if group_data[group].enabled:
			_enabled_groups.append(group)

	apply_configuration(input_map_data)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey

		if key_event.keycode in [4194325, 4194326, 4194328]:
			return
		var keycode: String = str(key_event.keycode)
		if not key_map.has(keycode):
			return
		if key_event.is_pressed() and pressed.has(keycode):
			return

		if key_event.is_released():
			if pressed.has(keycode):
				for action: String in pressed.get(keycode):
					Input.action_release(action)
				pressed.erase(keycode)
			return

		var subgroup: int = 0
		if key_event.alt_pressed:
			subgroup = subgroup | FLAGS.ALT
		if key_event.ctrl_pressed:
			subgroup = subgroup | FLAGS.CTRL
		if key_event.shift_pressed:
			subgroup = subgroup | FLAGS.SHIFT

		var actions: Array = resolve_actions(key_map[keycode], str(subgroup))

		pressed[keycode] = actions
		for action: String in actions:
			Input.action_press(action)

func resolve_actions(key_options: Dictionary, subgroup: String) -> Array:
	var subgroup_int: int = int(subgroup)
	var result: Array = []

	if key_options.has(subgroup):
		for group in key_options[subgroup]:
			if group_enabled(group):
				result.append_array(key_options[subgroup][group])
	if not result.is_empty():
		return result

	var fallback: int = 0
	for modifier: int in key_priority:
		fallback = modifier & subgroup_int
		if fallback > 0 and key_options.has(str(fallback)):
			for group in key_options[str(fallback)]:
				if group_enabled(group):
					result.append_array(key_options[str(fallback)][group])
			if not result.is_empty():
				return result

	if key_options.has('0'):
		return key_options.get('0')

	return result
#endregion

#region: configuration handling
func load_groups() -> Dictionary:
	var file_content: String = FileAccess.get_file_as_string('res://adv_input_groups.conf')

	return JSON.parse_string(file_content)

func load_configuration() -> Dictionary:
	var default: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://adv_input_map.conf'))
	var parsed: Dictionary = default

	if FileAccess.file_exists('user://input_map.conf'):
		var custom: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('user://input_map.conf'))

		for binding: String in custom:
			if parsed.has(binding):
				parsed[binding].deadzone = custom[binding].deadzone
				parsed[binding].events = custom[binding].events

		return parsed

	store_configuration({})

	return parsed

func store_configuration(content: Dictionary) -> void:
	var map_file: FileAccess = FileAccess.open('user://input_map.conf', FileAccess.WRITE)
	map_file.store_string(JSON.stringify(content, '', false))
	map_file.close()

func apply_configuration(bindings: Dictionary) -> void:
	var subgroup: int
	var binding_config: Dictionary
	for binding in bindings:
		binding_config = bindings[binding]

		for config: Dictionary in binding_config.events:
			subgroup = 0
			if config.alt_pressed:
				subgroup = subgroup | FLAGS.ALT
			if config.ctrl_pressed:
				subgroup = subgroup | FLAGS.CTRL
			if config.shift_pressed:
				subgroup = subgroup | FLAGS.SHIFT

			if not key_map.has(str(config.physical_keycode)):
				key_map[str(config.physical_keycode)] = {}
			var key_map_by_code: Dictionary = key_map[str(config.physical_keycode)]
			if not key_map_by_code.has(str(subgroup)):
				key_map_by_code[str(subgroup)] = {}
			var key_map_subgroup: Dictionary = key_map_by_code[str(subgroup)]
			if not key_map_subgroup.has(binding_config.group):
				key_map_subgroup[binding_config.group] = []
			var key_map_group: Array = key_map_subgroup[binding_config.group]

			key_map_group.append(binding)
#endregion

#region: runtime handling
func get_key_groups() -> Array:
	return groups.keys()

func enable_group(group_name: String) -> void:
	if not groups[group_name]:
		groups[group_name] = true
		_enabled_groups.append(group_name)

func disable_group(group_name: String) -> void:
	if groups[group_name]:
		groups[group_name] = false
		_enabled_groups.remove_at(_enabled_groups.find(group_name))

func group_enabled(group_name: String) -> bool:
	if group_name == '':
		return true
	
	return _enabled_groups.find(group_name) != -1
#endregion
