@tool
extends EditorPlugin

var _aim_popup_scene: PackedScene = preload('res://addons/advanced_input_map/editor/aim_popup.tscn')
var _adv_input: Panel


func _enter_tree() -> void:
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
