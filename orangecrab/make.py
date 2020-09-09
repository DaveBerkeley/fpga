#!/usr/bin/env python3

import os
import argparse

from edalize import *

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='run edalize')
    parser.add_argument('--lpf', dest='lpf')
    parser.add_argument('--tool', dest='tool')
    parser.add_argument('--project', dest='project')
    parser.add_argument('--top', dest='top', default='top')
    parser.add_argument('files', nargs='+')

    args = parser.parse_args()

    work_root = 'build'
    if not os.path.exists(work_root):
        os.makedirs(work_root)

    files = []

    for fname in args.files:
        d =  { 'name' : os.path.relpath(fname, work_root), 'file_type' : 'verilogSource' }
        files.append(d)

    if args.lpf:
        d = { 'name' : os.path.relpath(args.lpf, work_root), 'file_type' : 'LPF'}
        files.append(d)

    parameters = {
        #'clk_freq_hz' : {'datatype' : 'int', 'default' : 1000, 'paramtype' : 'vlogparam'},
        #'vcd' : {'datatype' : 'bool', 'paramtype' : 'plusarg'}
    }

    tool = args.tool

    if not tool:
        raise Exception('no --tool specified (eg. icarus, yosys, trellis)')
    if not args.project:
        raise Exception('no --project name specified')

    edam = {
        'files'        : files,
        'name'         : args.project,
        'parameters'   : parameters,
        'toplevel'     : args.top,
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

    backend.configure()
    backend.build()

    args = {
        # TODO dunno
        #'vcd' : True,
    }

    backend.run(args)

# FIN
