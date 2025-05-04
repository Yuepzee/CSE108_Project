// server.js - A dedicated WebSocket server for Godot multiplayer
const WebSocket = require('ws');

// Create a WebSocket server on port 8080
const port = process.env.PORT || 8080;
const wss = new WebSocket.Server({ port });

// Store connected clients
const clients = new Map();
let clientIdCounter = 0;

console.log('WebSocket server started on port 8080');

// Handle new connections
wss.on('connection', (ws) => {
    const clientId = clientIdCounter++;
    clients.set(ws, { id: clientId, username: null });
    
    console.log(`Client ${clientId} connected`);
    
    // Handle messages from clients
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            
            // Handle various message types
            switch (data.type) {
                case 'join':
                    // Set the username for this client
                    clients.get(ws).username = data.username;
                    console.log(`Client ${clientId} registered as "${data.username}"`);
                    break;
                    
                case 'chat':
                    // Broadcast chat message to all clients
                    const sender = clients.get(ws).username || `Client ${clientId}`;
                    console.log(`Message from ${sender}: ${data.message}`);
                    
                    const broadcastData = JSON.stringify({
                        type: 'chat',
                        username: sender,
                        message: data.message
                    });
                    
                    // Send to all connected clients
                    clients.forEach((client, clientWs) => {
                        if (clientWs.readyState === WebSocket.OPEN) {
                            clientWs.send(broadcastData);
                        }
                    });
                    break;
                    
                default:
                    console.log(`Unknown message type: ${data.type}`);
            }
        } catch (error) {
            console.error('Error processing message:', error);
        }
    });
    
    // Handle client disconnection
    ws.on('close', () => {
        console.log(`Client ${clientId} disconnected`);
        clients.delete(ws);
    });
});