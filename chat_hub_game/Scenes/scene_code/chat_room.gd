extends Node2D

@onready var join = $Join
@onready var username = $Username
@onready var send = $Send
@onready var message = $Message
@onready var chat_display = $ChatDisplay

var real_user : String
var is_connected = false
var websocket = WebSocketPeer.new()
var server_url = "ws://localhost:8080"  # Change this to your server's address when deploying

# For toggling chat visibility
var is_chat_visible = false

func _ready():
	# Hide the chat UI by default
	visible = false

func _process(delta):
	# Toggle chat visibility with T key
	if Input.is_action_just_pressed("toggle_chat"):  # Define this input in Project Settings
		is_chat_visible = !is_chat_visible
		visible = is_chat_visible
		if is_chat_visible:
			message.grab_focus()
	
	# When visible and Send button is pressed or Enter key is pressed while input has focus
	if visible and Input.is_action_just_pressed("ui_accept") and message.has_focus() and not Input.is_key_pressed(KEY_SPACE):
		_on_send_pressed()
	
	# Handle WebSocket state
	if is_connected:
		websocket.poll()
		var state = websocket.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			while websocket.get_available_packet_count():
				var packet = websocket.get_packet()
				var data = JSON.parse_string(packet.get_string_from_utf8())
				_handle_message(data)
		
		elif state == WebSocketPeer.STATE_CLOSING or state == WebSocketPeer.STATE_CLOSED:
			is_connected = false
			print("Disconnected from server")

func _on_join_pressed():
	if username.text.strip_edges() == "":
		# Show error or notification that username is required
		return
	
	real_user = username.text
	
	# Connect to WebSocket server
	var err = websocket.connect_to_url(server_url)
	if err != OK:
		print("Failed to connect to server: ", err)
		return
	
	is_connected = true
	
	# Hide join UI elements
	join.hide()
	username.hide()
	
	# Send join message once connection is established
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(func(): _send_join_message())
	add_child(timer)
	timer.start()
	
	print("Connecting to server as: " + real_user)

func _send_join_message():
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var join_data = JSON.stringify({
			"type": "join",
			"username": real_user
		})
		websocket.send_text(join_data)
		print("Joined server as: " + real_user)

func _on_send_pressed():
	if message.text.strip_edges() != "" and is_connected:
		var chat_data = JSON.stringify({
			"type": "chat",
			"message": message.text
		})
		websocket.send_text(chat_data)
		print("Sending message: " + message.text)
		message.text = ""
		# Return focus to message input for continuous chat
		message.grab_focus()

func _handle_message(data):
	if data and typeof(data) == TYPE_DICTIONARY:
		if data.has("type") and data["type"] == "chat":
			var username = data["username"]
			var msg = data["message"]
			print("Received message from " + username + ": " + msg)
			chat_display.text += str(username, ": ", msg, "\n")
