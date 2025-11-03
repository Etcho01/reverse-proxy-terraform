#!/usr/bin/env python3
"""
Simple Flask Backend Application
Serves on port 5000 (non-privileged port)
"""

from flask import Flask, jsonify
import socket
import os

app = Flask(__name__)

@app.route('/')
def home():
    """Health check endpoint"""
    hostname = socket.gethostname()
    try:
        ip = socket.gethostbyname(hostname)
    except:
        ip = "unknown"
    
    return jsonify({
        'status': 'healthy',
        'message': 'Backend server is running!',
        'hostname': hostname,
        'ip': ip,
        'environment': os.environ.get('ENV', 'dev')
    })

@app.route('/health')
def health():
    """Dedicated health check"""
    return jsonify({'status': 'ok'}), 200

@app.route('/info')
def info():
    """Server information"""
    return jsonify({
        'server': 'Flask Backend',
        'version': '1.0.0',
        'hostname': socket.gethostname()
    })

if __name__ == '__main__':
    # Run on port 5000 (non-privileged, doesn't require root)
    app.run(host='0.0.0.0', port=5000, debug=False)