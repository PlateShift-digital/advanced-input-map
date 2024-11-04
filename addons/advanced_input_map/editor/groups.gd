@tool
extends VBoxContainer

signal list_changed()
signal group_removed(group_name: String)
signal group_renamed(old_name: String, new_name: String)

@onready var aim_tree_parent: PanelContainer = $PanelContainer
@onready var new_input: LineEdit = $HBoxContainer/AddNew
@onready var new_button: Button = $HBoxContainer/AddNewButton

var _aim_tree: Tree
var _root: TreeItem
var remove_texture: CompressedTexture2D = preload('res://addons/advanced_input_map/icons/Remove.svg')


func _ready() -> void:
	new_input.text_changed.connect(_on_new_input_text_changed)
	new_input.text_submitted.connect(_on_new_input_text_submitted)
	new_button.pressed.connect(_on_new_button_pressed)

func set_data(data: Dictionary) -> void:
	render(data)

func get_data() -> Dictionary:
	var new_data: Dictionary = {}

	_root = _aim_tree.get_root()
	for group: TreeItem in _root.get_children():
		new_data[group.get_metadata(1)] = {
			'enabled': group.is_checked(0),
		}

	return new_data

#region: tree rendering
func render(data: Dictionary) -> void:
	if _aim_tree:
		_aim_tree.queue_free()
	_aim_tree = Tree.new()
	_aim_tree.item_edited.connect(_on_item_edited)
	_aim_tree.button_clicked.connect(_on_button_clicked)

	_aim_tree.column_titles_visible = true
	_aim_tree.hide_root = true
	_aim_tree.columns = 3
	_aim_tree.set_column_title(0, 'Enabled')
	_aim_tree.set_column_expand(0, false)
	_aim_tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	_aim_tree.set_column_title(1, 'Group Name')
	_aim_tree.set_column_expand(1, true)
	_aim_tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	_aim_tree.set_column_expand(2, false)

	var _root: TreeItem = _aim_tree.create_item()

	for key in data:
		add_group_item(_root, key, data[key])

	aim_tree_parent.add_child(_aim_tree)

func add_group_item(parent: TreeItem, key: String, group: Dictionary) -> void:
	var item: TreeItem = _aim_tree.create_item(parent)
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	item.set_checked(0, group.enabled)
	item.set_editable(0, true)

	item.set_text(1, key)
	item.set_metadata(1, key)
	item.set_editable(1, true)

	item.add_button(2, remove_texture)
#endregion

#region: tree events
func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if column == 2:
		group_removed.emit(item.get_text(1))
		item.free()

func _on_item_edited() -> void:
	var item: TreeItem = _aim_tree.get_edited()
	var column: int = _aim_tree.get_edited_column()

	if column == 0:
		list_changed.emit()
	if column == 1:
		if get_data().has(item.get_text(column)):
			item.set_text(1, item.get_metadata(1))
			return

		var old_name: String = item.get_metadata(1)
		item.set_metadata(1, item.get_text(1))
		group_renamed.emit(old_name, item.get_text(1))
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

	add_group_item(_root, new_input.text, {'enabled': false})
	new_input.text = ''
	new_input.text_changed.emit('')
	list_changed.emit()
#endregion
