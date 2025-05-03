extends Node2D

@onready var host = $Host
@onready var join = $Join
@onready var username = $Username
@onready var send = $Send
@onready var message = $Message
@onready var chat_display = $ChatDisplay
@onready var username_label = $UsernameLabel
@onready var chat_panel = $ChatPanel

var real_user : String
var is_initialized = false
var can_send_message := true
var chat_cooldown_timer : Timer
var chat_visible := false

func _ready():
	# Initialize UI elements with null checks
	if chat_panel:
		chat_panel.visible = false
	else:
		push_error("ChatPanel node not found - chat functionality will be limited")
	
	if username_label:
		username_label.visible = false
	else:
		push_warning("UsernameLabel node not found - username won't be displayed")
	
	if is_instance_valid(join):
		join.disabled = true
	if is_instance_valid(host):
		host.disabled = true
	
	# Setup cooldown timer
	chat_cooldown_timer = Timer.new()
	add_child(chat_cooldown_timer)
	chat_cooldown_timer.wait_time = 1.0
	chat_cooldown_timer.one_shot = true
	chat_cooldown_timer.timeout.connect(_on_cooldown_end)
	
	# Connect signals
	if is_instance_valid(username):
		username.text_changed.connect(_on_username_changed)
	else:
		push_error("Username node not found - connection will fail")
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	if not InputMap.has_action("toggle_chat"):
		push_warning("'toggle_chat' input action not found - chat toggle won't work")

func _on_cooldown_end():
	can_send_message = true
	if is_instance_valid(send):
		send.disabled = false

func _on_username_changed(new_text):
	if not is_instance_valid(join) or not is_instance_valid(host):
		return
		
	var has_username = new_text.strip_edges() != ""
	join.disabled = !has_username
	host.disabled = !has_username

func _input(event):
	if not is_initialized:
		return
		
	if event.is_action_pressed("toggle_chat"):
		toggle_chat()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and chat_visible and can_send_message:
		_on_send_pressed()
		get_viewport().set_input_as_handled()

func toggle_chat():
	if not is_instance_valid(chat_panel):
		return
		
	chat_visible = !chat_visible
	chat_panel.visible = chat_visible
	
	if chat_visible:
		if is_instance_valid(message):
			message.grab_focus()
		get_tree().call_group("players", "set_chatting", true)
	else:
		if is_instance_valid(message):
			message.release_focus()
		get_tree().call_group("players", "set_chatting", false)

func _on_host_pressed():
	if not is_instance_valid(username) or username.text.strip_edges() == "":
		print("Please enter a username before hosting")
		return
		
	var peer := WebSocketMultiplayerPeer.new()
	var result = peer.create_server(8080)
	
	if result != OK:
		print("Failed to start server")
		return

	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer
	
	if is_instance_valid(host): host.hide()
	if is_instance_valid(join): join.hide()
	if is_instance_valid(username): username.hide()
	
	real_user = username.text if is_instance_valid(username) else "Unknown"
	if is_instance_valid(username_label):
		username_label.text = real_user
		username_label.visible = true
	
	is_initialized = true
	print("Hosting server as: " + real_user)

func _on_join_pressed():
	if not is_instance_valid(username) or username.text.strip_edges() == "":
		print("Please enter a username before joining")
		return
		
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_client("ws://localhost:8080")
	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer
	
	if is_instance_valid(host): host.hide()
	if is_instance_valid(join): join.hide()
	if is_instance_valid(username): username.hide()
	
	real_user = username.text if is_instance_valid(username) else "Unknown"
	if is_instance_valid(username_label):
		username_label.text = "Player: " + real_user
		username_label.visible = true
	
	is_initialized = true
	print("Joined server as: " + real_user)

func _on_send_pressed():
	if not is_instance_valid(message) or message.text.strip_edges() == "" or not is_initialized or not can_send_message:
		return
		
	print("Sending message: " + message.text)
	rpc("msg_rpc", real_user, message.text)
	message.text = ""
	
	# Start cooldown
	can_send_message = false
	if is_instance_valid(send):
		send.disabled = true
	chat_cooldown_timer.start()
	
	if is_instance_valid(message):
		message.grab_focus()

@rpc("any_peer", "call_local", "reliable")
func msg_rpc(sender_name: String, msg_text: String):
	print("Received message from " + sender_name + ": " + msg_text)
	if is_instance_valid(chat_display):
		chat_display.text += str(sender_name, ": ", msg_text, "\n")
		chat_display.scroll_vertical = chat_display.get_line_count()

func joined():
	if is_instance_valid(host): host.hide()
	if is_instance_valid(join): join.hide()
	if is_instance_valid(username):
		real_user = username.text

func _on_peer_connected(id):
	print("Player connected: ", id)
	if is_instance_valid(chat_display):
		chat_display.text += str("Player ", id, " connected\n")

func _on_peer_disconnected(id):
	print("Player disconnected: ", id)
	if is_instance_valid(chat_display):
		chat_display.text += str("Player ", id, " disconnected\n")
