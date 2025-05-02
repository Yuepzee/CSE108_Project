extends Node2D

@onready var host = $Host
@onready var join = $Join
@onready var username = $Username
@onready var send = $Send
@onready var message = $Message
@onready var chat_display = $ChatDisplay  # Add a separate TextEdit or RichTextLabel for displaying messages

var real_user : String
var msg : String

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(1027)
	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer
	# Setup UI for host
	host.hide()
	join.hide()
	real_user = username.text
	username.hide()
	print("Hosting server as: " + real_user)  # Debug print

func _on_join_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 1027)
	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer
	joined()
	print("Joined server as: " + real_user)  # Debug print

func _on_send_pressed():
	if message.text.strip_edges() != "":
		print("Sending message: " + message.text)  # Debug print
		rpc("msg_rpc", real_user, message.text)
		message.text = ""  # Clear the input field after sending

@rpc("any_peer", "call_local")
func msg_rpc(username, data):
	print("Received message from " + username + ": " + data)  # Debug print
	chat_display.text += str(username, ": ", data, "\n")  # Add to display field, not input field

func joined():
	host.hide()
	join.hide()
	username.hide()
	real_user = username.text
