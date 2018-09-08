import SocketServer

include "io.pyx"
include "packet.pyx"


class NetworkHandler(SocketServer.BaseRequestHandler):
    BUFFER_SIZE = 1024

    def __init__(self, *args, **kwargs):
        self._packet_processor = PacketProcessor(self)

        self._authenticated = False
        self._username = None

        SocketServer.BaseRequestHandler.__init__(self, *args, **kwargs)

    @property
    def authenticated(self):
        return self._authenticated

    @authenticated.setter
    def authenticated(self, authenticated):
        self._authenticated = authenticated

    @property
    def username(self):
        return self._username

    @username.setter
    def username(self, username):
        self._username = username

    def setup(self):
        self.server.add_handler(self)

    def send_packet(self, data_buffer):
        self.request.sendall(data_buffer.data)
        data_buffer.clear()

    def handle(self):
        data_buffer = DataBuffer(self.request.recv(self.BUFFER_SIZE))

        while data_buffer.get_remaining_size():
            try:
                packet_id = data_buffer.read_byte()
            except AssertionError:
                break

            self._packet_processor.handle_packet(packet_id, data_buffer)

    def disconnect(self):
        self.request.close()

    def finish(self):
        self.server.remove_handler(self)

class NetworkThreadingMixIn(SocketServer.ThreadingMixIn):
    daemon_threads = True

class NetworkAcceptor(NetworkThreadingMixIn, SocketServer.TCPServer):
    allow_reuse_address = True

    def __init__(self, *args, **kwargs):
        SocketServer.TCPServer.__init__(self, *args, **kwargs)

        self._handlers = []

    def has_handler(self, handler):
        return handler in self._handlers

    def add_handler(self, handler):
        if self.has_handler(handler):
            return

        self._handlers.append(handler)

    def remove_handler(self, handler):
        if not self.has_handler(handler):
            return

        self._handlers.remove(handler)
