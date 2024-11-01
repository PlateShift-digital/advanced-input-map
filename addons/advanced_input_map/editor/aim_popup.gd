@tool
extends Panel

@onready var input_map: VBoxContainer = $'MarginContainer/TabContainer/Input Map'
@onready var groups: VBoxContainer = $MarginContainer/TabContainer/Groups
@onready var overlay_panel: Panel = $OverlayPanel
@onready var group_select: Panel = $OverlayPanel/GroupSelect
@onready var bind_input: Panel = $OverlayPanel/BindInput


func _ready() -> void:
	var config: Dictionary = load_input()

	input_map.list_changed.connect(_on_list_changed)
	input_map.binding_group_select_executed.connect(_on_binding_group_select_executed)
	input_map.event_hotkey_binding_executed.connect(_on_event_hotkey_binding_executed)
	groups.list_changed.connect(_on_list_changed)
	groups.group_removed.connect(_on_group_removed)
	groups.group_renamed.connect(_on_group_renamed)

	input_map.data = config.input
	groups.data = config.groups

	group_select.reload_group_options(config.groups.keys())
	group_select.group_selected.connect(_on_group_select_group_selected)
	bind_input.binding_event_confirmed.connect(_on_binding_event_confirmed)
	bind_input.binding_event_canceled.connect(_on_binding_event_canceled)
	render()

func render() -> void:
	input_map.render()
	groups.render()

#region: configuration management
func load_input() -> Dictionary:
	return {
		'input': load_input_map(),
		'groups': load_input_groups(),
	}

func load_input_groups() -> Dictionary:
	if FileAccess.file_exists('res://adv_input_groups.conf'):
		return JSON.parse_string(FileAccess.get_file_as_string('res://adv_input_groups.conf'))

	return {}

func load_input_map() -> Dictionary:
	if FileAccess.file_exists('res://adv_input_map.conf'):
		return JSON.parse_string(FileAccess.get_file_as_string('res://adv_input_map.conf'))

	var action: Dictionary
	var converted: Dictionary = {}
	for action_name in get_project_input_list():
		action = ProjectSettings.get('input/' + action_name)
		converted[action_name] = {
			'deadzone': action.deadzone,
			'events': [],
			'group': '',
		}
		
		for event: InputEvent in action.events:
			if event is InputEventKey:
				converted[action_name].events.append({
					'alt_pressed': event.alt_pressed,
					'shift_pressed': event.shift_pressed,
					'ctrl_pressed': event.ctrl_pressed,
					'physical_keycode': event.physical_keycode,
					'unicode': event.unicode,
				})
	
	return converted

func handle_configuration_change() -> void:
	var input_map_data: Dictionary = input_map.get_data()
	var groups_data: Dictionary = groups.get_data()

	group_select.reload_group_options(groups_data.keys())

	store_config_file(input_map_data, groups_data)
	store_project_settings()

func store_config_file(input_map_data: Dictionary, groups_data: Dictionary) -> void:
	var map_file: FileAccess = FileAccess.open('res://adv_input_map.conf', FileAccess.WRITE)
	map_file.store_string(JSON.stringify(input_map_data, ""))
	map_file.close()

	var groups_file: FileAccess = FileAccess.open('res://adv_input_groups.conf', FileAccess.WRITE)
	groups_file.store_string(JSON.stringify(groups_data, ""))
	groups_file.close()

func store_project_settings() -> void:
	for input_name in get_project_input_list():
		ProjectSettings.set('input/' + input_name, null)

	for input_name in input_map.data:
		ProjectSettings.set('input/' + input_name, {"deadzone": 0.5, "events": []})

	ProjectSettings.save()
#endregion

#region: group bindings
func _on_list_changed() -> void:
	handle_configuration_change()

func _on_binding_group_select_executed(binding: String) -> void:
	overlay_panel.show()
	group_select.start_group_selection(binding, input_map.get_data()[binding].group)

func _on_group_select_group_selected(binding: String, group: String) -> void:
	overlay_panel.hide()
	var input_map_data: Dictionary = input_map.get_data()
	input_map_data[binding].group = group

	input_map.data = input_map_data
	input_map.render()

	handle_configuration_change()

func _on_group_removed(group_name: String) -> void:
	var map_data = input_map.get_data()
	for bind_key in map_data:
		if group_name == map_data[bind_key].group:
			map_data[bind_key].group = ''

	input_map.data = map_data
	input_map.render()

	handle_configuration_change()

func _on_group_renamed(old_name: String, new_name: String) -> void:
	var map_data = input_map.get_data()
	for bind_key in map_data:
		if old_name == map_data[bind_key].group:
			map_data[bind_key].group = new_name

	input_map.data = map_data
	input_map.render()

	handle_configuration_change()
#endregion

#region: event binding
func _on_event_hotkey_binding_executed(binding: String, index: int) -> void:
	var event: InputEvent = null
	if index != -1:
		event = InputEventKey.new()
		event.alt_pressed = input_map.data[binding].events[index].alt_pressed
		event.shift_pressed = input_map.data[binding].events[index].shift_pressed
		event.ctrl_pressed = input_map.data[binding].events[index].ctrl_pressed
		event.physical_keycode = input_map.data[binding].events[index].physical_keycode
		event.unicode = input_map.data[binding].events[index].unicode

	bind_input.show_binding_menu(binding, index, event)
	overlay_panel.show()

func _on_binding_event_confirmed(binding: String, index: int, event: InputEvent) -> void:
	var event_data: Dictionary = {
		'alt_pressed': event.alt_pressed,
		'shift_pressed': event.shift_pressed,
		'ctrl_pressed': event.ctrl_pressed,
		'physical_keycode': event.physical_keycode,
		'unicode': event.unicode,
	}

	if index != -1:
		input_map.data[binding].events[index] = event_data
	else:
		input_map.data[binding].events.append(event_data)

	bind_input.hide()
	overlay_panel.hide()
	render()

	handle_configuration_change()

func _on_binding_event_canceled() -> void:
	bind_input.hide()
	overlay_panel.hide()
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
