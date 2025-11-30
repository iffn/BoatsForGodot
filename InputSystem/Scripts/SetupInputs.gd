extends Node

@export var input_collection : InputCollection

# Called when the node enters the scene tree for the first time.
func _ready():
	# Define your input actions and their associated keys
	setup_input_actions()

func setup_input_actions():
	# Iterate over the inputs create each input action
	for inputResource in input_collection.inputs:
		var input_name := inputResource.input_name
		var input := inputResource.input
		
		print("setting up input " + input_name)
		
		# Ensure the action doesn't already exist to avoid duplication
		if not InputMap.has_action(input_name):
			InputMap.add_action(input_name)
		
		# Create a new InputEventKey for the action
		var input_event := InputEventKey.new()
		input_event.keycode = input
		
		# Add the event to the action
		InputMap.action_add_event(input_name, input_event)
