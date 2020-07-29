MEMORY
{
    ROM (xr)  : ORIGIN = 0x00100000, LENGTH = 0x20000
    RAM (rw)  : ORIGIN = 0x00000000, LENGTH = 0x20000
}
SECTIONS {
    .text :
    {
        . = ALIGN(4);
        _stext = .;
        *(.text)
        *(.text*)
        . = ALIGN(4);
        _etext = .;
        _sidata = _etext;
    } >ROM
    .data : AT ( _sidata )
    {
        . = ALIGN(4);
        _sdata = .;
        _ram_start = .;
        . = ALIGN(4);
        *(.data)
        *(.data*)
        *(.sdata)
        *(.sdata*)
        *(.rodata)
        *(.rodata*)
        *(.srodata)
        *(.srodata*)
        . = ALIGN(4);
        _edata = .;
    } >RAM
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.bss*)
        *(.sbss)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } >RAM

    .heap :
    {
        . = ALIGN(4);
        _sheap = .;
        . = 0x10000;
        _eheap = .;
    } >RAM

    _ram_end = ORIGIN(RAM) + LENGTH(RAM) - 1;
    _stack_size = _ram_end - _eheap;

    .stack :
    {
        . = ALIGN(4);
        _sstack = .;
        . = _stack_size; 
        . = ALIGN(8);
        _estack = .;
    } >RAM
}
