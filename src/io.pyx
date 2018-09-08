import struct


cdef class DataBuffer(object):
    cdef object _data
    cdef int _offset

    def __init__(self, data=bytes(), offset=0):
        self._data = data
        self._offset = offset

    @property
    def data(self):
        return self._data

    @data.setter
    def data(self, data):
        self._data = data

    @property
    def offset(self):
        return self._offset

    @offset.setter
    def offset(self, offset):
        self._offset = offset

    cdef object get_remaining_data(self):
        return self._data[self._offset:]

    cdef int get_remaining_size(self):
        return len(self.get_remaining_data())

    cdef object read(self, length):
        data = self._data[self._offset:][:length]
        self._offset += length
        return data

    cdef void write(self, data):
        self._data += data
        self._offset += len(data)

    def read_from(self, fmt):
        data = struct.unpack_from(fmt, self._data, self._offset)
        self._offset += struct.calcsize(fmt)
        return data

    def write_to(self, fmt, *args):
        self.write(struct.pack(fmt, *args))

    def read_byte(self):
        value, = self.read_from('!b')
        return int(value)

    def write_byte(self, value):
        self.write_to('!b', int(value))

    def read_string(self, length=64):
        return self.read(length).strip()

    def write_string(self, string, length=64):
        self.write(string + ''.join(['\x20'] * (length - len(string))))

    def read_array(self, length=1024):
        return bytes(self.read(length))

    def write_array(self, data, length=1024):
        self.write(data + bytes().join(['\x00'] * (length - len(data))))

    def clear(self):
        self._data = bytes()
        self._offset = 0
