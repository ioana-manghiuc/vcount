import subprocess
import sys
import time
import webbrowser
import socket
from pathlib import Path

def resource_path(relative):
    """
    Get resource path for both development and packaged (PyInstaller) environments.
    In PyInstaller's onefile mode, sys._MEIPASS contains the temp extraction directory.
    In development, we resolve from the current file location.
    """
    if hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS) / relative
    return (Path(__file__).parent / relative).resolve()

BACKEND_DIR = Path(__file__).parent
URL = "http://127.0.0.1:8000"

def find_free_port(host="127.0.0.1", start_port=8000, max_attempts=10):
    """Find a free port in case default is in use."""
    port = start_port
    for _ in range(max_attempts):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind((host, port))
                return port
        except OSError:
            port += 1
    raise RuntimeError(f"Could not find free port starting from {start_port}")

def start_backend():
    port = find_free_port()
    return subprocess.Popen(
        [
            sys.executable,
            "-m",
            "uvicorn",
            "app.main:app",
            "--host", "127.0.0.1",
            "--port", str(port)
        ],
        cwd=BACKEND_DIR
    ), port

if __name__ == "__main__":
    process, port = start_backend()
    time.sleep(3)  # Give backend time to start
    
    url = f"http://127.0.0.1:{port}"
    print(f"Opening {url}")
    webbrowser.open(url)
    
    try:
        process.wait()
    except KeyboardInterrupt:
        process.terminate()
        process.wait()
