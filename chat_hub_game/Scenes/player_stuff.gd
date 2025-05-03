extends CharacterBody2D
@export var speed = 100
@export var start_Dir : Vector2 = Vector2(0, 1)
#parameters/Idle/blend_position
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var chat_menu = $ChatMenu  # Reference to your chat menu scene
@onready var username_label = $UsernameLabel

var chat_open = false  # Track if chat is open

func _ready():
	update_animation_parameters(start_Dir)
	# Check if chat_menu exists
	if chat_menu:
		print("Chat menu found!")
		chat_menu.visible = false
	else:
		print("ERROR: Chat menu not found! Make sure it's added as a child node named 'ChatMenu'")
	
func _physics_process(_delta):
	# Only process movement if chat is not open
	if not chat_open:
		# Get input direction
		var input_dir = Vector2(
			Input.get_action_raw_strength("right") - Input.get_action_raw_strength("left"),
			Input.get_action_raw_strength("down") - Input.get_action_raw_strength("up")
		)
		
		update_animation_parameters(input_dir)
		
		#update velocity
		velocity = input_dir * speed
		
		#move and slide function using velocity of character body to move charcter on map
		move_and_slide()
		#pick new state function allows player to do a walk animation when moving
		pick_new_state()

# Add this function to handle input separately from physics
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:  # Check if T key is pressed
			print("T key pressed!")
			toggle_chat()
		elif event.is_action_pressed("toggle_chat"):  # Also check action mapping
			print("toggle_chat action detected!")
			toggle_chat()

# Function to toggle chat visibility
func toggle_chat():
	chat_open = !chat_open
	print("Toggle chat called, chat_open is now: ", chat_open)
	if chat_menu:
		chat_menu.visible = chat_open
		print("Chat menu visibility set to: ", chat_menu.visible)
		
		# If chat is now open, set focus to the message input
		if chat_open and chat_menu.has_node("Message"):
			chat_menu.get_node("Message").grab_focus()
			print("Focus set to Message input")
	else:
		print("ERROR: Can't toggle chat menu - not found!")
	
func update_animation_parameters(move_input : Vector2):
	#Don't chage animation parameters if there is no move input
	if(move_input != Vector2.ZERO):
		animation_tree.set("parameters/Walk/blend_position", move_input)
		animation_tree.set("parameters/Idle/blend_position", move_input)
		
func pick_new_state():
	if(velocity != Vector2.ZERO):
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")
