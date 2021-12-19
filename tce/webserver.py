#!/usr/bin/env micropython

def http_get(url):
    import socket
    _, _, host, path = url.split('/', 3)
    addr = socket.getaddrinfo(host, 80)[0][-1]
    s = socket.socket()
    s.connect(addr)
    s.send(bytes('GET /%s HTTP/1.0\r\nHost: %s\r\n\r\n' % (path, host), 'utf8'))
    while True:
        data = s.recv(100)
        if data:
            print(str(data, 'utf8'), end='')
        else:
            break
    s.close()
http_get('http://micropython.org/ks/test.html')

## https://docs.micropython.org/en/latest/library/network.html

html = """<!DOCTYPE html>
<html>
    <head> <title>ESP8266 Pins</title> </head>
    <body> <h1>ESP8266 Pins</h1>
        <table border="1"> <tr><th>Pin</th><th>Value</th></tr> %s </table>
    </body>
</html>
"""

## https://docs.micropython.org/en/latest/esp8266/tutorial/network_tcp.html#simple-http-server
#pin = false

pins = [ ['a',0], ['b',1], ['c',2] ]

import socket

text_addr = '0.0.0.0'
port = 8000

addr = socket.getaddrinfo(text_addr, port)[0][-1]

s = socket.socket()
s.bind(addr)
s.listen(1)

print('listening on', text_addr,':', port)

while True:
    cl, addr = s.accept()
    print('client connected from', socket.inet_ntop(socket.AF_INET, addr[4:8]))
    cl_file = cl.makefile('rwb', 0)
    while True:
        line = cl_file.readline()
        if not line or line == b'\r\n':
            break
    rows = [ '<tr><td>%s</td><td> %d</td></tr>' %  (str(p), p[1]) for p in pins]
    response = html % '\n'.join(rows)
    cl.send('HTTP/1.0 200 OK\r\nContent-type: text/html\r\n\r\n')
    cl.send(response)
    cl.close()

