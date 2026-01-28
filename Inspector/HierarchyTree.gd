extends Tree

@export var boat_syncronizer : BoatEditSyncronizer

func _ready() -> void:
	# Start the process from a specific node (e.g., the scene root)
	render_tree(boat_syncronizer.calculation_boat.boat_model)

func render_tree(target_node: Node) -> void:
	clear()
	if target_node:
		_create_tree_branch(target_node, null)
		_update_tree_height()

func _create_tree_branch(node: Node, parent_item: TreeItem) -> void:
	var new_item = create_item(parent_item)
	new_item.set_text(0, node.name)
	for child in node.get_children():
		_create_tree_branch(child, new_item)

func _add_children_to_tree(parent_node: Node, parent_item: TreeItem) -> void:
	for child in parent_node.get_children():
		var child_item = create_item(parent_item)
		child_item.set_text(0, child.name)
		_add_children_to_tree(child, child_item)

func _update_tree_height() -> void:
	var root = get_root()
	if not root:
		return
	
	var row_count = _count_visible_items(root)
	var row_height = get_theme_constant("item_margin") + 24
	
	custom_minimum_size.y = row_count * row_height

func _count_visible_items(item: TreeItem) -> int:
	var count = 1
	if not item.collapsed:
		var child = item.get_first_child()
		while child:
			count += _count_visible_items(child)
			child = child.get_next()
	return count
