import sys

include "network.pyx"


cdef int main():
    HOST, PORT = '0.0.0.0', 25565

    server = NetworkAcceptor((HOST, PORT), NetworkHandler)
    server.serve_forever(poll_interval=0.01)

    return 0

if __name__ == '__main__':
    sys.exit(main())
