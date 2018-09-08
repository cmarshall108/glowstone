import enum


class ClientPacketTypes(enum.Enum):
    """
    Enum containing valid client packet id's corresponding to their packet handler
    """

    PLAYER_IDENT = 0x00
    SET_BLOCK = 0x05
    POSITION_AND_ORIENTATION = 0x08
    MESSAGE = 0x0d

class ServerPacketTypes(enum.Enum):
    """
    Enum containing valid server packet id's corresponding to their packet handler
    """

    SERVER_IDENT = 0x00
    PING = 0x01
    LEVEL_INITIALIZE = 0x02
    LEVEL_DATA_CHUNK = 0x03
    LEVEL_FINALIZE = 0x04
    SET_BLOCK = 0x06
    SPAWN_PLAYER = 0x07
    POSITION_AND_ORIENTATION_TELEPORT = 0x08
    POSITION_AND_ORIENTATION_UPDATE = 0x09
    POSITION_UPDATE = 0x0a
    ORIENTATION_UPDATE = 0x0b
    DESPAWN_PLAYER = 0x0c
    DISCONNECT_PLAYER = 0x0e
    UPDATE_USER_TYPE = 0x0f

cdef class PacketProcessor(object):
    """
    Unpacks/Packs incoming packets from the socket object
    """

    cdef object _handler
    cdef object _packet_handlers

    def __init__(self, handler):
        self._handler = handler
        self._packet_handlers = {
            ClientPacketTypes.PLAYER_IDENT.value: self.handle_player_ident,
        }

    @property
    def handler(self):
        return self._handler

    @property
    def handlers(self):
        return self._handlers

    cdef object has_packet(self, packet_id):
        """
        Returns true if the packet exists else false
        """

        return packet_id in self._packet_handlers

    cdef object get_packet(self, packet_id):
        """
        Attempts to retrieve the corresponding packet from the dictionary
        """

        return self._packet_handlers.get(packet_id)

    def handle_packet(self, packet_id, data_buffer):
        """
        Attempts to process an incoming packet and call it's handler
        """

        if not self.has_packet(packet_id):
            self.handle_unknown_packet(packet_id)
            return

        packet_handler = self.get_packet(packet_id)
        packet_handler(data_buffer)

    def handle_player_ident(self, data_buffer):
        try:
            protocol_version = data_buffer.read_byte()
            username = data_buffer.read_string()
            verification_key = data_buffer.read_string()
            protocol_type = data_buffer.read_byte()
        except AssertionError:
            self._handler.disconnect()
            return

        self._handler.authenticated = True
        self._handler.username = username

        data_buffer = DataBuffer()
        data_buffer.write_byte(ServerPacketTypes.SERVER_IDENT.value)
        data_buffer.write_byte(protocol_version)
        data_buffer.write_string('A Minecraft Classic Server')
        data_buffer.write_string('A Minecraft MOTD')
        data_buffer.write_byte(0x64)

        self._handler.send_packet(data_buffer)

    cdef void handle_unknown_packet(self, packet_id):
        """
        Handle an unknown packet handler for packet
        """
