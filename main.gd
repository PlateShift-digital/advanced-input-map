extends Control

@onready var panel: VBoxContainer = $HSplitContainer/ScrollContainer/ActionEvents
@onready var input_list: VBoxContainer = $HSplitContainer/VSplitContainer/InputList
@onready var groups_list: VBoxContainer = $HSplitContainer/VSplitContainer/GroupsList
@onready var scroll_bar: VScrollBar = $HSplitContainer/ScrollContainer.get_v_scroll_bar()

var max_scroll_length: float


func _ready() -> void:
	max_scroll_length = scroll_bar.max_value
	scroll_bar.changed.connect(_on_scroll_bar_changed)
	
	var new_label: Label
	for action: String in get_project_input_list():
		new_label = Label.new()
		new_label.name = action
		new_label.text = action
		new_label.add_theme_color_override('font_color', Color.ORANGE_RED)
		input_list.add_child(new_label)
	
	if get_tree().root.has_node('AdvancedInput'):
		var new_group: CheckBox
		for group: String in AdvancedInput.get_key_groups():
			new_group = CheckBox.new()
			new_group.name = group
			new_group.text = group
			new_group.button_pressed = AdvancedInput.group_enabled(group)
			new_group.toggled.connect(_on_group_toggled)
			groups_list.add_child(new_group)

func _process(_delta: float) -> void:
	var display_label: Label
	var new_label: Label
	
	for action: String in get_project_input_list():
		display_label = input_list.get_node(action)
		
		if Input.is_action_just_pressed(action):
			new_label = Label.new()
			new_label.text = action + ' pressed'
			panel.add_child(new_label)
			display_label.add_theme_color_override('font_color', Color.GREEN_YELLOW)
		if Input.is_action_just_released(action):
			new_label = Label.new()
			new_label.text = action + ' released'
			panel.add_child(new_label)
			display_label.add_theme_color_override('font_color', Color.ORANGE_RED)

func get_project_input_list() -> Array:
	var item_name: String
	var items: Array
	
	for item: Dictionary in ProjectSettings.get_property_list():
		item_name = item.name
		if item_name.begins_with('input/') and not item_name.begins_with('input/ui_'):
			items.append(item_name.substr(6))
	
	return items

func _on_group_toggled(toggled_on: bool) -> void:
	if toggled_on:
		AdvancedInput.enable_group(get_viewport().gui_get_focus_owner().name)
	else:
		AdvancedInput.disable_group(get_viewport().gui_get_focus_owner().name)

func _on_scroll_bar_changed() -> void:
	if max_scroll_length != scroll_bar.max_value: 
		max_scroll_length = scroll_bar.max_value 
		scroll_bar.set_value_no_signal(max_scroll_length)
