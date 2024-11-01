@tool
extends VBoxContainer

signal list_changed()
signal binding_group_select_executed(binding: String)
signal event_hotkey_binding_executed(binding: String, index: int)

@onready var filter_input: LineEdit = $Filter
@onready var add_new_input: LineEdit = $HBoxContainer/AddNew
@onready var add_new_button: Button = $HBoxContainer/AddNewButton
@onready var aim_tree_parent: Control = $PanelContainer
@onready var new_input: LineEdit = $HBoxContainer/AddNew
@onready var new_button: Button = $HBoxContainer/AddNewButton

var data: Dictionary
var add_texture: CompressedTexture2D = preload('res://addons/advanced_input_map/icons/Add.svg')
var edit_texture: CompressedTexture2D = preload('res://addons/advanced_input_map/icons/Edit.svg')
var remove_texture: CompressedTexture2D = preload('res://addons/advanced_input_map/icons/Remove.svg')
var key_texture: CompressedTexture2D = preload('res://addons/advanced_input_map/icons/InputEventKey.svg')
var aim_tree: Tree


func _ready() -> void:
	new_input.text_changed.connect(_on_new_input_text_changed)
	new_input.text_submitted.connect(_on_new_input_text_submitted)
	new_button.pressed.connect(_on_new_button_pressed)

	render()

func get_data() -> Dictionary:
	var new_data: Dictionary = {}
	var event_key: InputEventKey

	var root: TreeItem = aim_tree.get_root()
	for binding: TreeItem in root.get_children():
		var events: Array[Dictionary] = []

		for event_item in binding.get_children():
			event_key = event_item.get_metadata(0)
			events.append({
				'alt_pressed': event_key.alt_pressed,
				'shift_pressed': event_key.shift_pressed,
				'ctrl_pressed': event_key.ctrl_pressed,
				'physical_keycode': event_key.physical_keycode,
				'unicode': event_key.unicode,
			})

		new_data[binding.get_text(0)] = {
			'group': binding.get_text(1),
			'deadzone': binding.get_range(2),
			'events': events,
		}

	return new_data

#region: tree rendering
func render() -> void:
	if aim_tree:
		aim_tree.queue_free()
	aim_tree = Tree.new()
	aim_tree.item_edited.connect(_on_item_edited)
	aim_tree.button_clicked.connect(_on_button_clicked)
	aim_tree.item_activated.connect(_on_item_activated)
	aim_tree.item_icon_double_clicked.connect(_on_item_edited)


	aim_tree.column_titles_visible = true
	aim_tree.hide_root = true
	aim_tree.columns = 5
	aim_tree.set_column_title(0, 'Binding')
	aim_tree.set_column_expand_ratio(0, 3)
	aim_tree.set_column_expand(0, true)
	aim_tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	aim_tree.set_column_title(1, 'Group')
	aim_tree.set_column_expand_ratio(1, 1)
	aim_tree.set_column_expand(1, true)
	aim_tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	aim_tree.set_column_title(2, 'Deadzone')
	aim_tree.set_column_title_alignment(2, HORIZONTAL_ALIGNMENT_LEFT)
	aim_tree.set_column_expand(2, false)
	aim_tree.set_column_expand(3, false)
	aim_tree.set_column_expand(4, false)

	var root: TreeItem = aim_tree.create_item()

	for key in data:
		add_binding_item(root, key, data[key])

	aim_tree_parent.add_child(aim_tree)

func add_binding_item(parent: TreeItem, key: String, binding: Dictionary) -> void:
	var item: TreeItem = aim_tree.create_item(parent)
	item.set_text(0, key)
	item.set_metadata(0, key)
	item.set_editable(0, true)

	item.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	item.set_text(1, str(binding.group))

	item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	item.set_range_config(2, 0.0, 1.0, 0.01)
	item.set_range(2, binding.deadzone)
	item.set_editable(2, true)

	item.add_button(3, add_texture)
	item.add_button(4, remove_texture)

	for event: Dictionary in binding.events:
		add_key_item(item, event)

func add_key_item(parent: TreeItem, event: Dictionary) -> void:
	var event_key: InputEventKey = InputEventKey.new()
	event_key.alt_pressed = event.alt_pressed
	event_key.shift_pressed = event.shift_pressed
	event_key.ctrl_pressed = event.ctrl_pressed
	event_key.physical_keycode = event.physical_keycode
	event_key.unicode = event.unicode

	var item: TreeItem = aim_tree.create_item(parent)
	item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	item.set_icon(0, key_texture)
	item.set_text(0, event_key.as_text())
	item.set_metadata(0, event_key)

	item.add_button(3, edit_texture)
	item.add_button(4, remove_texture)
#endregion

#region: tree events
func get_key_sorted_dict(dictionary: Dictionary) -> Dictionary:
	var new_dict: Dictionary = {}
	var keys: Array = dictionary.keys()
	keys.sort()
	for key in keys:
		new_dict[key] = dictionary[key]
	return new_dict

func resolve_depth(item: TreeItem) -> int:
	var depth: int = 0

	while item.get_parent() is TreeItem:
		depth = depth + 1
		item = item.get_parent()

	return depth

func _on_item_edited() -> void:
	var item: TreeItem = aim_tree.get_edited()
	var column: int = aim_tree.get_edited_column()
	var depth: int = resolve_depth(item)

	if depth == 1:
		if column == 0:
			if data.has(item.get_text(column)):
				render()
				return

			var new_data: Dictionary = {}
			data[item.get_text(0)] = data[item.get_metadata(0)]
			data.erase(item.get_metadata(0))
			data = get_key_sorted_dict(data)
			render()
			list_changed.emit()
		if column == 2:
			data[item.get_metadata(0)].deadzone = item.get_range(column)
			render()
			list_changed.emit()

func _on_item_activated() -> void:
	var item: TreeItem = aim_tree.get_selected()
	var column: int = aim_tree.get_selected_column()
	var depth: int = resolve_depth(item)

	if depth == 1:
		if column == 1:
			binding_group_select_executed.emit(item.get_metadata(0))
	if depth == 2:
		if column == 0 or column == 1:
			var bind_name: String = item.get_parent().get_text(0)
			var bind_index: int = item.get_parent().get_children().find(item)

			event_hotkey_binding_executed.emit(bind_name, bind_index)

func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var depth: int = resolve_depth(item)

	if depth == 1:
		if column == 3:
			var bind_name: String = item.get_text(0)
			event_hotkey_binding_executed.emit(bind_name, -1)
		if column == 4:
			data.erase(item.get_text(0))
			render()
			list_changed.emit()
	if depth == 2:
		if column == 3:
			var bind_name: String = item.get_parent().get_text(0)
			var bind_index: int = item.get_parent().get_children().find(item)

			event_hotkey_binding_executed.emit(bind_name, bind_index)
		if column == 4:
			var bind_name: String = item.get_parent().get_text(0)
			var bind_index: int = item.get_parent().get_children().find(item)

			data[bind_name].events.remove_at(bind_index)
			render()
			list_changed.emit()
#endregion

#region: input form events
func _on_new_input_text_changed(new_text: String) -> void:
	if new_text != '' and not data.has(new_text):
		new_button.disabled = false
	else:
		new_button.disabled = true

func _on_new_input_text_submitted(new_text: String) -> void:
	if new_text != '' and not data.has(new_text):
		_on_new_button_pressed()

func _on_new_button_pressed() -> void:
	if data.has(new_input.text):
		new_input.text = ''
		new_input.text_changed.emit('')
		return

	data[new_input.text] = {
		'group': '',
		'deadzone': 0.5,
		'events': [],
	}
	new_input.text = ''
	new_input.text_changed.emit('')
	render()
	list_changed.emit()
#endregion
