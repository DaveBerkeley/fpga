/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

#include <stdlib.h>
#include <errno.h>

// Memory locations defined in the linker config.
extern "C" uint32_t _stext, _etext, _sdata, _edata, _sheap, _eheap, _sstack, _estack;

    /*
     *  _sbrk() is used by malloc() to alloc heap memory.
     */

extern "C" void *_sbrk(intptr_t increment)
{
    static void *heap = (void*) & _sheap;

    void *base = heap;

    void *next = & ((char *) base)[increment];

    if (next >= (void*) & _eheap)
    {
        errno = ENOMEM;
        return (void*) -1;
    }

    heap = next;
    return base;
}

#define LEDS  ((uint32_t*) 0x40000000)
#define uart  ((uint32_t*) 0x50000000)
#define flash ((uint32_t*) 0x70000000)

// banner made with : figlet "SERV Risc-V" | sed 's/\\/\\\\/g'
char banner[] = 
"\r\n"
"  ____  _____ ______     __  ____  _            __     __\r\n"
" / ___|| ____|  _ \\ \\   / / |  _ \\(_)___  ___   \\ \\   / /\r\n"
" \\___ \\|  _| | |_) \\ \\ / /  | |_) | / __|/ __|___\\ \\ / / \r\n"
"  ___) | |___|  _ < \\ V /   |  _ <| \\__ \\ (_|_____\\ V /  \r\n"
" |____/|_____|_| \\_\\ \\_/    |_| \\_\\_|___/\\___|     \\_/   \r\n"
"\r\n"
"The World's smallest RISC-V CPU. Using Bit-serial Architecture.\r\n"
"\r\n"
"https://github.com/olofk/serv\r\n\r\n";

    /*
     *
     */

void print_num(uint32_t n, uint32_t base, uint32_t digits)
{
    if (digits > 1)
    {
        print_num(n / base, base, digits-1);
    }

    n %= base;
    *uart = (n > 9) ? ('a' + n - 10) : ('0' + n);
}

void print_dec(uint32_t n)
{
    print_num(n, 10, 8);
}

    /*
     *
     */

void print(const char *text)
{
    for (const char *s = text; *s; s++)
    {
        *uart = *s;
    }
}

    /*
     *
     */

void show_section(const char* text, uint32_t *start, uint32_t *end)
{
    uint32_t s = (uint32_t) start;
    uint32_t e = (uint32_t) end;

    print(text);
    print(" addr 0x");
    print_num(s, 16, 6);
    print(" size 0x");
    print_num(e - s, 16, 6);
    print("\r\n");
}

    /*
     *
     */

void main()
{
    *LEDS = 0;

    print(banner);

    print("RAM ");
    print_num((uint32_t) &_estack, 10, 6);
    print(" bytes\r\n");
    print("\r\n");
    show_section("Program :", & _stext, & _etext);
    show_section("Data    :", & _sdata, & _edata);
    show_section("Heap    :", & _sheap, & _eheap);
    show_section("Stack   :", & _sstack, & _estack);
    print("\r\n");


    print("Run audio engine .. TODO\r\n");

    uint16_t mask = 1;

    while (true)
    {
        *LEDS = mask;
        mask <<= 1;
        if (mask > 0x20)
            mask = 1;
        uint32_t v = 0;
        for (int i = 0; i < 1000; i++)
            v |= *LEDS;
    }
}
