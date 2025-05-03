extends Node
# Server script for Godot WebSocket chat application

func _ready():
	print("Starting chat server on port ", get_port())
	var peer := WebSocketMultiplayerPeer.new()
	var result = peer.create_server(get_port())
	
	if result != OK:
		print("Failed to start server: ", result)
		return
		
	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer
	print("Server started successfully!")

# Get port from environment variable or use default
func get_port() -> int:
	if OS.has_environment("PORT"):
		return OS.get_environment("PORT").to_int()
	return 8080

@rpc("any_peer", "call_local")
func msg_rpc(username, data):
	print("Received message from ", username, ": ", data)
	# The any_peer mode will automatically relay the RPC to all connected peers
	# No need to explicitly call rpc() again
