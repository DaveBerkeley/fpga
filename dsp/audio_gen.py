#!/usr/bin/env python3

# https://old.reddit.com/r/Python/comments/6g9ccc/it_is_ridiculously_easy_to_generate_any_audio/

import argparse
import sys
import struct
import wave

SFREQ = 31250
SAMPLE_LEN = SFREQ * 30  # 30 seconds of audio

ofile = wave.open('tick.wav', 'w')

ofile.setparams((2, 2, SFREQ, 0, 'NONE', 'not compressed'))

parser = argparse.ArgumentParser(description='create wav file from input')
parser.add_argument("--tick", action="store_true", help="generate tick file")
parser.add_argument("--binary", action="store_true", help="read binary file")
parser.add_argument("--text", action="store_true", help="read text file")
parser.add_argument("filename", nargs='?', help="read text file")

args = parser.parse_args()

values = []

if args.text:

    with open(args.filename, 'r') as f:

        for line in f:
            value = int(line, 16)
            packed_value = struct.pack('H', value)
            values.append(packed_value)

if args.binary:

    with open(args.filename, 'rb') as f:

        while True:
            # add to left and right
            value = f.read(2)
            if not value:
                break
            values.append(value)

if args.tick:

    for i in range(0, SAMPLE_LEN):
        if (i % (2 * 1024)):
            value = 32000 # periodic impulse
        else:
            value = 0
        packed_value = struct.pack('h', value)
        # add to left and right
        values.append(packed_value)
        values.append(packed_value)

value_str = b''.join(values)
ofile.writeframes(value_str)

ofile.close()

# FIN
