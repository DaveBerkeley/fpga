#!/usr/bin/env python3

import sys

path = sys.argv[1]
opath = sys.argv[2]

print("in", path)
print("out", opath)

with open(path) as f:
    with open(opath, "wb") as of:
        for line in f:
            line = line.strip()
            if (line == '0'):
                break
            v = int(line, 16)
            x = v.to_bytes(4, byteorder='little', signed=False)
            print(line, x)
            of.write(x)

# FIN
