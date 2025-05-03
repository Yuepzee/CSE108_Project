extends Control

@onready var user = $PanelContainer/MarginContainer/VBoxContainer/GridContainer/user
@onready var password = $PanelContainer/MarginContainer/VBoxContainer/GridContainer/password
@onready var http_request = HTTPRequest.new()
@onready var ws = WebSocketPeer.new()  # WebSocket client for connecting to the server

var server_url = "ws://localhost:8080"  # Update with your WebSocket server URL
var login_url = "http://localhost:5000/login"  # Update with your backend login URL

func _ready():
	# Create an HTTP request node and connect its completion signal
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

# Called when the login button is pressed
func _on_button_pressed() -> void:
	var fields = {"username" : user.text, "password" : password.text}
	var body = JSON.new().stringify(fields)
	
	# Perform a POST request to login
	var result = http_request.request(login_url, [], HTTPClient.METHOD_POST, body)
	if result != OK:
		push_error("An error occurred in the POST request.")

# Called when the HTTP request is completed
func _http_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var err = json.parse(body.get_string_from_utf8())
		if err == OK:
			var response = json.get_data()
			
			if response.has("token"):
				var token = response["token"]
				print("Login successful! Token: ", token)
				_connect_to_websocket(token)
			else:
				push_error("Login failed: No token received")
		else:
			push_error("Error parsing the response: %s" % json.get_error_message())
	else:
		push_error("Login failed with response code: %d" % response_code)

# Connect to WebSocket server using the JWT token
func _connect_to_websocket(token: String) -> void:
	ws.connect_to_url(server_url + "?token=" + token)  # Send the token as a query parameter
	# Use Callable to connect signals in Godot 4
	ws.connect("data_received", Callable(self, "_on_message_received"))
	ws.connect("connection_closed", Callable(self, "_on_connection_closed"))
	print("Connecting to WebSocket server...")

# Called when a message is received from the WebSocket server
func _on_message_received(message: String) -> void:
	print("Received message: ", message)

# Called when the WebSocket connection is closed
func _on_connection_closed() -> void:
	print("WebSocket connection closed.")
