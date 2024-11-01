extends Node

enum FLAGS {
	SHIFT = 1,
	ALT = 2,
	CTRL = 4,
}

var key_map: Dictionary = {}
var groups: Dictionary = {}
var pressed: Dictionary = {}

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

	apply_configuration(input_map_data)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey

		if [4194325, 4194326, 4194328].find(key_event.keycode) != -1:
			return
		var keycode: String = str(key_event.keycode)
		if not key_map.has(keycode):
			return
		if key_event.is_pressed() and pressed.has(keycode):
			return

		var subgroup: int = 0
		if key_event.alt_pressed:
			subgroup = subgroup | FLAGS.ALT
		if key_event.ctrl_pressed:
			subgroup = subgroup | FLAGS.CTRL
		if key_event.shift_pressed:
			subgroup = subgroup | FLAGS.SHIFT

		var group_actions: Array = resolve_group_action(key_map[keycode], str(subgroup))

		if key_event.is_released():
			if pressed.has(keycode):
				Input.action_release(pressed.get(keycode))
				pressed.erase(keycode)
			return

		for group_action in group_actions:
			var group: String = group_action.substr(0, group_action.find('/'))
			var action: String = group_action.substr(group_action.find('/') + 1)
			if group == '' or groups[group]:
				pressed[keycode] = action
				Input.action_press(action)

func resolve_group_action(key_options: Dictionary, subgroup: String) -> Array:
	var subgroup_int: int = int(subgroup)

	if key_options.has(subgroup):
		return key_options.get(subgroup)

	var fallback: int = 0
	for modifier: int in key_priority:
		fallback = modifier & subgroup_int
		if fallback > 0 and key_options.has(str(fallback)):
			return key_options.get(str(fallback))

	if key_options.has('0'):
		return key_options.get('0')

	return []
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
	map_file.store_string(JSON.stringify(content))
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
			if not key_map[str(config.physical_keycode)].has(str(subgroup)):
				key_map[str(config.physical_keycode)][str(subgroup)] = []

			key_map[str(config.physical_keycode)][str(subgroup)].append(binding_config.group + '/' + binding)
#endregion

#region: runtime handling
func get_key_groups() -> Dictionary:
	return groups

func enable_group(group_name: String) -> void:
	groups[group_name] = true

func disable_group(group_name: String) -> void:
	groups[group_name] = false

func group_enabled(group_name: String) -> bool:
	return groups[group_name]
#endregion
