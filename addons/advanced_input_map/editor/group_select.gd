@tool
extends Panel

signal group_selected(binding: String, group: String)

@onready var container: VBoxContainer = $MarginContainer/VBoxContainer

var group_options: OptionButton
var confirm_button: Button
var _target_binding: String
var _target_group: String


func _ready() -> void:
	group_options = OptionButton.new()
	
	confirm_button = Button.new()
	confirm_button.text = 'Confirm'
	
	container.add_child(group_options)
	container.add_child(confirm_button)
	
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	group_options.item_selected.connect(_on_group_option_item_selected)

func start_group_selection(binding: String, group: String) -> void:
	_target_binding = binding
	_target_group = group

	for id: int in range(group_options.item_count):
		if group_options.get_item_metadata(id) == _target_group:
			group_options.select(id)
			break

	show()

func reload_group_options(groups: Array) -> void:
	for id: int in range(group_options.item_count):
		group_options.remove_item(0)

	group_options.add_item('none', 0)
	group_options.set_item_metadata(0, '')
	group_options.add_separator('')

	var index: int = 2
	for group in groups:
		group_options.add_item(group, index)
		group_options.set_item_metadata(index, group)
		index = index + 1

func _on_confirm_button_pressed() -> void:
	group_selected.emit(_target_binding, _target_group)
	hide()

func _on_group_option_item_selected(index: int) -> void:
	_target_group = group_options.get_selected_metadata()
