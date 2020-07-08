#!/usr/bin/env python3

import math

addr_bits = 7
gain_bits = 16

points = 1 << addr_bits
gain = (1 << (gain_bits - 1)) - 1
dc = 1 << (gain_bits - 1)

print("// Auto-Generated : do not edit")
print("")

print("function signed [(%d-1):0] sin(input [(%d-1):0] addr);" % (gain_bits, addr_bits))
print("begin")

for i in range(points):

    rad = (i * 2 * math.pi) / points
    value = math.sin(rad) * gain
    value = int(value)
    #value += dc
    value &= 0xFFFF

    print("        if (addr == %d) sin = 16'h%04x;" % (i, value))

print("end")
print("endfunction")

# FIN
