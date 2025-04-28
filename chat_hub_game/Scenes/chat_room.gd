#https://www.youtube.com/watch?v=kJ45IAcNLCg&ab_channel=Gwizz
extends Node2D
@onready var host = $Host
@onready var join = $Join
@onready var username = $Username
@onready var send = $Send
@onready var message = $Message

var real_user : String
var msg : String

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(1027)
	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer

func _on_join_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 1027)
	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer
	joined()

func _on_send_pressed():
	rpc("msg_rpc", real_user, message.text)

@rpc ("any_peer", "call_local")

func msg_rpc(user, data):
	message.text += str(user, ": ", data, "/n")

func joined():
	host.hide()
	join.hide()
	username.hide()
	real_user = username.text
