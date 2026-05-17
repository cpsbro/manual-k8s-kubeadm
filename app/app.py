from flask import Flask
import socket

app = Flask(__name__)

# Main application endpoint
@app.route("/")
def home():
    return {
        "message": "Kubernetes App Running",
        "hostname": socket.gethostname()
    }

# Health check endpoint (VERY IMPORTANT for HAProxy / Kubernetes)
@app.route("/health")
def health():
    return "ok", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
