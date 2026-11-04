"""Serve the local prototype without retaining old builds in browser caches."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import socket


class PrototypeHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def send_head(self):
        # A client with an earlier cached build must receive the full response.
        for header in ('If-Modified-Since', 'If-None-Match'):
            if header in self.headers:
                del self.headers[header]
        return super().send_head()


class PrototypeServer(ThreadingHTTPServer):
    allow_reuse_address = False

    def server_bind(self):
        # Windows otherwise permits several Python servers to share this port.
        if hasattr(socket, 'SO_EXCLUSIVEADDRUSE'):
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        super().server_bind()


if __name__ == '__main__':
    root = Path(__file__).resolve().parent / 'build' / 'web'
    server = PrototypeServer(
        ('127.0.0.1', 8080), partial(PrototypeHandler, directory=str(root)))
    print('MONTAS: http://127.0.0.1:8080/ (cache disabled)', flush=True)
    server.serve_forever()
