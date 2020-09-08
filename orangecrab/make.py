#!/usr/bin/env python3

import os

from edalize import *

work_root = 'build'

files = [
  {'name' : os.path.relpath('orangecrab.v', work_root), 'file_type' : 'verilogSource'},
  {'name' : os.path.relpath('orangecrab_r02.lpf', work_root), 'file_type' : 'LPF'},
]

parameters = {
    #'clk_freq_hz' : {'datatype' : 'int', 'default' : 1000, 'paramtype' : 'vlogparam'},
    #'vcd' : {'datatype' : 'bool', 'paramtype' : 'plusarg'}
}

#tool = 'icarus'
#tool = 'yosys'
tool = 'trellis'

edam = {
    'files'        : files,
    'name'         : 'blinky',
    'parameters'   : parameters,
    'toplevel'     : 'top',
    'tool_options' : {
        'yosys' : { 
            'arch' : 'ecp5', 
        },
        'trellis' : { 
            # For Orange Crab
            'nextpnr_options' : [ '--25k', '--package', 'CSFBGA285' ],
        },
    },
}

backend = get_edatool(tool)(edam=edam, work_root=work_root)

if not os.path.exists(work_root):
    os.makedirs(work_root)

backend.configure()
backend.build()

args = {
        # TODO dunno
    #'vcd' : True,
    #'aaaaa' : 'bbbbb',
}

backend.run(args)

# FIN
