# server.py - Flask SocketIO WebSocket server
from flask import Flask, render_template
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import json

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes
app.config['SECRET_KEY'] = 'godot-chat-secret'
socketio = SocketIO(app, cors_allowed_origins="*")

# Store connected clients
clients = {}
client_count = 0

@app.route('/')
def index():
    return "Godot Chat WebSocket Server is running"

@socketio.on('connect')
def handle_connect():
    global client_count
    client_id = client_count
    client_count += 1
    clients[request.sid] = {'id': client_id, 'username': None}
    print(f"Client {client_id} connected with SID: {request.sid}")

@socketio.on('disconnect')
def handle_disconnect():
    client_id = clients[request.sid]['id'] if request.sid in clients else 'Unknown'
    print(f"Client {client_id} disconnected")
    if request.sid in clients:
        del clients[request.sid]

@socketio.on('message')
def handle_message(data):
    try:
        if isinstance(data, str):
            data = json.loads(data)
        
        client_id = clients[request.sid]['id'] if request.sid in clients else 'Unknown'
        
        if data.get('type') == 'join':
            # Set the username for this client
            username = data.get('username')
            if request.sid in clients:
                clients[request.sid]['username'] = username
            print(f"Client {client_id} registered as '{username}'")
            
        elif data.get('type') == 'chat':
            # Get the username of the sender
            username = clients[request.sid]['username'] if request.sid in clients and clients[request.sid]['username'] else f"Client {client_id}"
            message = data.get('message')
            
            print(f"Message from {username}: {message}")
            
            # Broadcast to all clients
            broadcast_data = {
                'type': 'chat',
                'username': username,
                'message': message
            }
            emit('message', broadcast_data, broadcast=True)
            
    except Exception as e:
        print(f"Error handling message: {e}")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=8080, debug=True, allow_unsafe_werkzeug=True)