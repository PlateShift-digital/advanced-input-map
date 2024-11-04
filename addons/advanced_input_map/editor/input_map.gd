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

var drag_drop_script: GDScript = preload('res://addons/advanced_input_map/editor/drag_drop_list.gd')
var add_texture: CompressedTexture2D = preload('res://addons/advanced_input_map/icons/Add.svg')
var edit_texture: CompressedTexture2D = preload('res://addons/advanced_input_map/icons/Edit.svg')
var remove_texture: CompressedTexture2D = preload('res://addons/advanced_input_map/icons/Remove.svg')
var key_texture: CompressedTexture2D = preload('res://addons/advanced_input_map/icons/InputEventKey.svg')

var _aim_tree: Tree
var _root


func _ready() -> void:
	new_input.text_changed.connect(_on_new_input_text_changed)
	new_input.text_submitted.connect(_on_new_input_text_submitted)
	new_button.pressed.connect(_on_new_button_pressed)

func set_data(new_data: Dictionary) -> void:
	render(new_data)

func get_data() -> Dictionary:
	var new_data: Dictionary = {}
	var event_key: InputEventKey

	var root: TreeItem = _aim_tree.get_root()
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

		new_data[binding.get_metadata(0)] = {
			'group': binding.get_text(1),
			'deadzone': binding.get_range(2),
			'events': events,
		}

	return new_data

#region: tree rendering
func render(data: Dictionary) -> void:
	if _aim_tree:
		_aim_tree.queue_free()
	_aim_tree = drag_drop_script.new()
	_aim_tree.item_edited.connect(_on_item_edited)
	_aim_tree.button_clicked.connect(_on_button_clicked)
	_aim_tree.item_activated.connect(_on_item_activated)
	_aim_tree.item_icon_double_clicked.connect(_on_item_edited)
	_aim_tree.list_sorted.connect(_on_tree_list_sorted)

	_aim_tree.column_titles_visible = true
	_aim_tree.hide_root = true
	_aim_tree.columns = 5
	_aim_tree.set_column_title(0, 'Binding')
	_aim_tree.set_column_expand_ratio(0, 3)
	_aim_tree.set_column_expand(0, true)
	_aim_tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	_aim_tree.set_column_title(1, 'Group')
	_aim_tree.set_column_expand_ratio(1, 1)
	_aim_tree.set_column_expand(1, true)
	_aim_tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	_aim_tree.set_column_title(2, 'Deadzone')
	_aim_tree.set_column_title_alignment(2, HORIZONTAL_ALIGNMENT_LEFT)
	_aim_tree.set_column_expand(2, false)
	_aim_tree.set_column_expand(3, false)
	_aim_tree.set_column_expand(4, false)

	_root = _aim_tree.create_item()

	for key in data:
		add_binding_item(_root, key, data[key])

	aim_tree_parent.add_child(_aim_tree)

func add_binding_item(parent: TreeItem, key: String, binding: Dictionary) -> void:
	var item: TreeItem = _aim_tree.create_item(parent)
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

	var item: TreeItem = _aim_tree.create_item(parent)
	item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	item.set_icon(0, key_texture)
	item.set_text(0, event_key.as_text())
	item.set_metadata(0, event_key)

	item.add_button(3, edit_texture)
	item.add_button(4, remove_texture)
#endregion

#region: tree events
func resolve_depth(item: TreeItem) -> int:
	var depth: int = 0

	while item.get_parent() is TreeItem:
		depth = depth + 1
		item = item.get_parent()

	return depth

func _on_item_edited() -> void:
	var item: TreeItem = _aim_tree.get_edited()
	var column: int = _aim_tree.get_edited_column()
	var depth: int = resolve_depth(item)

	if depth == 1:
		if column == 0: # rename action
			if get_data().has(item.get_text(column)):
				item.set_text(column, item.get_metadata(column))
				return

			item.set_metadata(column, item.get_text(column))
			list_changed.emit()
		if column == 2: # deadzone changed
			list_changed.emit()

func _on_item_activated() -> void:
	var item: TreeItem = _aim_tree.get_selected()
	var column: int = _aim_tree.get_selected_column()
	var depth: int = resolve_depth(item)

	if depth == 1:
		if column == 1: # select group for action
			binding_group_select_executed.emit(item.get_metadata(0))
	if depth == 2:
		if column == 0 or column == 1: # change keybind
			var bind_name: String = item.get_parent().get_text(0)
			var bind_index: int = item.get_parent().get_children().find(item)

			event_hotkey_binding_executed.emit(bind_name, bind_index)

func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var depth: int = resolve_depth(item)

	if depth == 1: # action level
		if column == 3: # add keybind
			var bind_name: String = item.get_text(0)
			event_hotkey_binding_executed.emit(bind_name, -1)
		if column == 4: # delete action
			item.free()
			list_changed.emit()
	if depth == 2: # key-bind level
		if column == 3: # edit keybind
			var bind_name: String = item.get_parent().get_text(0)
			var bind_index: int = item.get_parent().get_children().find(item)

			event_hotkey_binding_executed.emit(bind_name, bind_index)
		if column == 4: # delete keybind
			item.free()
			list_changed.emit()

func _on_tree_list_sorted() -> void:
	list_changed.emit()
#endregion

#region: input form events
func _on_new_input_text_changed(new_text: String) -> void:
	if new_text != '' and not get_data().has(new_text):
		new_button.disabled = false
	else:
		new_button.disabled = true

func _on_new_input_text_submitted(new_text: String) -> void:
	if new_text != '' and not get_data().has(new_text):
		_on_new_button_pressed()

func _on_new_button_pressed() -> void:
	if get_data().has(new_input.text):
		new_input.text = ''
		new_input.text_changed.emit('')
		return

	add_binding_item(_root, new_input.text, {'group': '', 'deadzone': 0.5, 'events': []})

	new_input.text = ''
	new_input.text_changed.emit('')
	list_changed.emit()
#endregion
