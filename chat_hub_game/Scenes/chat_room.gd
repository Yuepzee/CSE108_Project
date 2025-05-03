extends Node2D

@onready var host = $Host
@onready var join = $Join
@onready var username = $Username
@onready var send = $Send
@onready var message = $Message
@onready var chat_display = $ChatDisplay

var real_user : String
var msg : String
var is_initialized = false

func _ready():
	# Hide the chat UI by default
	visible = false

# Called when T key toggles the chat visibility
func _process(_delta):
	# When visible and Send button is pressed or Enter key is pressed while input has focus
	if Input.is_action_just_pressed("ui_accept") and not Input.is_key_pressed(KEY_SPACE):
		_on_send_pressed()

func _on_host_pressed():
	var peer := WebSocketMultiplayerPeer.new()
	var result = peer.create_server(8080)
	
	if result != OK:
		print("Failed to start server")
		return

	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer
	# Setup UI for host
	host.hide()
	join.hide()
	real_user = username.text
	username.hide()
	is_initialized = true
	print("Hosting server as: " + real_user)

func _on_join_pressed():
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_client("ws://localhost:8080")
	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer
	joined()
	is_initialized = true
	print("Joined server as: " + real_user)

func _on_send_pressed():
	if message.text.strip_edges() != "" and is_initialized:
		print("Sending message: " + message.text)
		rpc("msg_rpc", real_user, message.text)
		message.text = ""
		# Return focus to message input for continuous chat
		message.grab_focus()

@rpc("any_peer", "call_local")
func msg_rpc(username, data):
	print("Received message from " + username + ": " + data)
	chat_display.text += str(username, ": ", data, "\n")

func joined():
	host.hide()
	join.hide()
	username.hide()
	real_user = username.text
