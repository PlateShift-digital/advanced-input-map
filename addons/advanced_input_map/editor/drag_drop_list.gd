extends Tree

signal list_sorted()


func _get_drag_data(at_position: Vector2) -> Variant:
	var items := []
	var next: TreeItem = get_next_selected(null)
	while next:
		if get_root() == next.get_parent():
			items.append(next)

		next = get_next_selected(next)

	return items

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	drop_mode_flags = Tree.DROP_MODE_INBETWEEN
	
	if data.is_empty():
		return false

	var item := get_item_at_position(at_position)
	if item in data:
		return false
		
	if resolve_depth(item) > 1:
		return false

	return true

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var drop_section := get_drop_section_at_position(at_position)
	var target_item := get_item_at_position(at_position)

	for i in data.size():
		var item := data[i] as TreeItem
		if drop_section == -1:
			item.move_before(target_item)
		elif drop_section == 1:
			if i == 0:
				item.move_after(target_item)
			else:
				item.move_after(data[i - 1])

	list_sorted.emit()

func resolve_depth(item: TreeItem) -> int:
	var depth: int = 0

	while item.get_parent() is TreeItem:
		depth = depth + 1
		item = item.get_parent()

	return depth
