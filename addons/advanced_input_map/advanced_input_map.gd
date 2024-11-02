@tool
extends EditorPlugin

var _aim_popup_scene: PackedScene = preload('res://addons/advanced_input_map/editor/aim_popup.tscn')
var _adv_input: Panel


func _enter_tree() -> void:
	convert_default_to_aim_input()
	
	var input_map_node: Control = get_node('/root').find_children('Input Map', 'ActionMapEditor', true, false)[0]
	var project_settings: TabContainer = input_map_node.get_parent()
	var input_map_index: int = project_settings.get_children().find(input_map_node)

	_adv_input = _aim_popup_scene.instantiate()
	_adv_input.name = 'Advanced Input Map'
	project_settings.set_tab_hidden(input_map_index, true)
	project_settings.add_child(_adv_input)
	project_settings.move_child(_adv_input, input_map_index)

	add_autoload_singleton('AdvancedInput', 'advanced_input.gd')

func _exit_tree() -> void:
	var input_map_node: Control = get_node('/root').find_children('Input Map', 'ActionMapEditor', true, false)[0]
	var project_settings: TabContainer = input_map_node.get_parent()
	var input_map_index: int = project_settings.get_children().find(input_map_node)

	project_settings.set_tab_hidden(input_map_index, false)

	if is_instance_valid(_adv_input):
		_adv_input.queue_free()

	remove_autoload_singleton('AdvancedInput')
	convert_aim_to_default_input()

#region: configuration swap handling
func convert_aim_to_default_input() -> void:
	if not FileAccess.file_exists('res://adv_input_map.conf'):
		return
	
	var input_map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://adv_input_map.conf'))
	
	var action: Dictionary
	var gd_action: Dictionary
	var key_event: InputEventKey
	
	for action_name in input_map:
		action = input_map[action_name]
		gd_action = {
			'deadzone': action.deadzone,
			'events': [],
		}
		
		for event: Dictionary in action.events:
			key_event = InputEventKey.new()
			key_event.alt_pressed = event['alt_pressed']
			key_event.shift_pressed = event['shift_pressed']
			key_event.ctrl_pressed = event['ctrl_pressed']
			key_event.physical_keycode = event['physical_keycode']
			key_event.unicode = event['unicode']
			
			gd_action.events.append(key_event)
		
		ProjectSettings.set('input/' + action_name, gd_action)
	
	ProjectSettings.save()

func convert_default_to_aim_input() -> void:
	var adv_input_map: Dictionary
	var adv_input_groups: Dictionary
	if FileAccess.file_exists('res://adv_input_map.conf'):
		adv_input_map = JSON.parse_string(FileAccess.get_file_as_string('res://adv_input_map.conf'))
	if not FileAccess.file_exists('res://adv_input_groups.conf'):
		var groups_file: FileAccess = FileAccess.open('res://adv_input_groups.conf', FileAccess.WRITE)
		groups_file.store_string(JSON.stringify({}, '', false))
		groups_file.close()
	
	var action: Dictionary
	for action_name in get_project_input_list():
		if not adv_input_map.has(action_name):
			action = ProjectSettings.get('input/' + action_name)
			adv_input_map[action_name] = {
				'deadzone': action.deadzone,
				'events': [],
				'group': '',
			}
			
			for event: InputEvent in action.events:
				if event is InputEventKey:
					adv_input_map[action_name].events.append({
						'alt_pressed': event.alt_pressed,
						'shift_pressed': event.shift_pressed,
						'ctrl_pressed': event.ctrl_pressed,
						'physical_keycode': event.physical_keycode,
						'unicode': event.unicode,
					})
			
			ProjectSettings.set('input/' + action_name, {'deadzone': action.deadzone, 'events': []})
		else:
			action = ProjectSettings.get('input/' + action_name)
			action.events = []
			ProjectSettings.set('input/' + action_name, action)
	
	var map_file: FileAccess = FileAccess.open('res://adv_input_map.conf', FileAccess.WRITE)
	map_file.store_string(JSON.stringify(adv_input_map, '', false))
	map_file.close()
	
	ProjectSettings.save()
	ProjectSettings.settings_changed.emit()
#endregion

#region: utitity
func get_project_input_list() -> Array:
	var item_name: String
	var items: Array

	for item in ProjectSettings.get_property_list():
		item_name = item.name
		if item_name.begins_with('input/') and not item_name.begins_with('input/ui_'):
			items.append(item_name.substr(6))

	return items
#endregion
