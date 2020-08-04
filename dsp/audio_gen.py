#!/usr/bin/env python3

# https://old.reddit.com/r/Python/comments/6g9ccc/it_is_ridiculously_easy_to_generate_any_audio/

import struct
import wave

SFREQ = 31250
SAMPLE_LEN = SFREQ * 30  # 30 seconds of audio

ofile = wave.open('tick.wav', 'w')

ofile.setparams((2, 2, SFREQ, 0, 'NONE', 'not compressed'))

values = []

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
