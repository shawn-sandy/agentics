#!/usr/bin/env python3
"""Print a free TCP port number to stdout and exit."""
import socket

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind(("", 0))
    print(s.getsockname()[1])
