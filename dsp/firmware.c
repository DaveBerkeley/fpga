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

#ifdef ICEBREAKER
#  define MEM_TOTAL 0x20000 /* 128 KB */
#elif HX8KDEMO
#  define MEM_TOTAL 0x200 /* 2 KB */
#else
#  error "Set -DICEBREAKER or -DHX8KDEMO when compiling firmware.c"
#endif

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define reg_spictrl (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)
#define reg_leds (*(volatile uint32_t*)0x03000000)

// --------------------------------------------------------

extern uint32_t flashio_worker_begin;
extern uint32_t flashio_worker_end;

void flashio(uint8_t *data, int len, uint8_t wrencmd)
{
    uint32_t func[&flashio_worker_end - &flashio_worker_begin];

    uint32_t *src_ptr = &flashio_worker_begin;
    uint32_t *dst_ptr = func;

    while (src_ptr != &flashio_worker_end)
        *(dst_ptr++) = *(src_ptr++);

    ((void(*)(uint8_t*, uint32_t, uint32_t))func)(data, len, wrencmd);
}

#ifdef HX8KDEMO
void set_flash_qspi_flag()
{
    uint8_t buffer[8];
    uint32_t addr_cr1v = 0x800002;

    // Read Any Register (RDAR 65h)
    buffer[0] = 0x65;
    buffer[1] = addr_cr1v >> 16;
    buffer[2] = addr_cr1v >> 8;
    buffer[3] = addr_cr1v;
    buffer[4] = 0; // dummy
    buffer[5] = 0; // rdata
    flashio(buffer, 6, 0);
    uint8_t cr1v = buffer[5];

    // Write Enable (WREN 06h) + Write Any Register (WRAR 71h)
    buffer[0] = 0x71;
    buffer[1] = addr_cr1v >> 16;
    buffer[2] = addr_cr1v >> 8;
    buffer[3] = addr_cr1v;
    buffer[4] = cr1v | 2; // Enable QSPI
    flashio(buffer, 5, 0x06);
}

void set_flash_latency(uint8_t value)
{
    reg_spictrl = (reg_spictrl & ~0x007f0000) | ((value & 15) << 16);

    uint32_t addr = 0x800004;
    uint8_t buffer_wr[5] = {0x71, addr >> 16, addr >> 8, addr, 0x70 | value};
    flashio(buffer_wr, 5, 0x06);
}

void set_flash_mode_spi()
{
    reg_spictrl = (reg_spictrl & ~0x00700000) | 0x00000000;
}

void set_flash_mode_dual()
{
    reg_spictrl = (reg_spictrl & ~0x00700000) | 0x00400000;
}

void set_flash_mode_quad()
{
    reg_spictrl = (reg_spictrl & ~0x00700000) | 0x00200000;
}

void set_flash_mode_qddr()
{
    reg_spictrl = (reg_spictrl & ~0x00700000) | 0x00600000;
}
#endif

#ifdef ICEBREAKER
void set_flash_qspi_flag()
{
    uint8_t buffer[8];

    // Read Configuration Registers (RDCR1 35h)
    buffer[0] = 0x35;
    buffer[1] = 0x00; // rdata
    flashio(buffer, 2, 0);
    uint8_t sr2 = buffer[1];

    // Write Enable Volatile (50h) + Write Status Register 2 (31h)
    buffer[0] = 0x31;
    buffer[1] = sr2 | 2; // Enable QSPI
    flashio(buffer, 2, 0x50);
}

void set_flash_mode_spi()
{
    reg_spictrl = (reg_spictrl & ~0x007f0000) | 0x00000000;
}

void set_flash_mode_dual()
{
    reg_spictrl = (reg_spictrl & ~0x007f0000) | 0x00400000;
}

void set_flash_mode_quad()
{
    reg_spictrl = (reg_spictrl & ~0x007f0000) | 0x00240000;
}

void set_flash_mode_qddr()
{
    reg_spictrl = (reg_spictrl & ~0x007f0000) | 0x00670000;
}

void enable_flash_crm()
{
    reg_spictrl |= 0x00100000;
}
#endif

// --------------------------------------------------------

void putchar(char c)
{
    if (c == '\n')
        putchar('\r');
    reg_uart_data = c;
}

void print(const char *p)
{
    while (*p)
        putchar(*(p++));
}

void print_hex(uint32_t v, int digits)
{
    for (int i = 7; i >= 0; i--) {
        char c = "0123456789abcdef"[(v >> (4*i)) & 15];
        if (c == '0' && i >= digits) continue;
        putchar(c);
        digits = i;
    }
}

void print_dec(uint32_t v)
{
    if (v >= 10000) {
        print(">=10000");
        return;
    }

    if      (v >= 9000) { putchar('9'); v -= 9000; }
    else if (v >= 8000) { putchar('8'); v -= 8000; }
    else if (v >= 7000) { putchar('7'); v -= 7000; }
    else if (v >= 6000) { putchar('6'); v -= 6000; }
    else if (v >= 5000) { putchar('5'); v -= 5000; }
    else if (v >= 4000) { putchar('4'); v -= 4000; }
    else if (v >= 3000) { putchar('3'); v -= 3000; }
    else if (v >= 2000) { putchar('2'); v -= 2000; }
    else if (v >= 1000) { putchar('1'); v -= 1000; }

    if      (v >= 900) { putchar('9'); v -= 900; }
    else if (v >= 800) { putchar('8'); v -= 800; }
    else if (v >= 700) { putchar('7'); v -= 700; }
    else if (v >= 600) { putchar('6'); v -= 600; }
    else if (v >= 500) { putchar('5'); v -= 500; }
    else if (v >= 400) { putchar('4'); v -= 400; }
    else if (v >= 300) { putchar('3'); v -= 300; }
    else if (v >= 200) { putchar('2'); v -= 200; }
    else if (v >= 100) { putchar('1'); v -= 100; }

    if      (v >= 90) { putchar('9'); v -= 90; }
    else if (v >= 80) { putchar('8'); v -= 80; }
    else if (v >= 70) { putchar('7'); v -= 70; }
    else if (v >= 60) { putchar('6'); v -= 60; }
    else if (v >= 50) { putchar('5'); v -= 50; }
    else if (v >= 40) { putchar('4'); v -= 40; }
    else if (v >= 30) { putchar('3'); v -= 30; }
    else if (v >= 20) { putchar('2'); v -= 20; }
    else if (v >= 10) { putchar('1'); v -= 10; }

    if      (v >= 9) { putchar('9'); v -= 9; }
    else if (v >= 8) { putchar('8'); v -= 8; }
    else if (v >= 7) { putchar('7'); v -= 7; }
    else if (v >= 6) { putchar('6'); v -= 6; }
    else if (v >= 5) { putchar('5'); v -= 5; }
    else if (v >= 4) { putchar('4'); v -= 4; }
    else if (v >= 3) { putchar('3'); v -= 3; }
    else if (v >= 2) { putchar('2'); v -= 2; }
    else if (v >= 1) { putchar('1'); v -= 1; }
    else putchar('0');
}

    /*
     *
     */

void __assert_func(const char *file, int line, const char *function, const char *expr)
{
    print("Assert failed : ");
    print(file);
    print(" +");
    print_dec(line);
    print(" ");
    print(function);
    print("() ");
    print(expr);
    print("\n");
    while (true) ;
}

#define ASSERT(x) assert(x)

    /*
     *
     */

char getchar_prompt(char *prompt)
{
    int32_t c = -1;

    uint32_t cycles_begin, cycles_now, cycles;
    __asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));

    if (prompt)
        print(prompt);

    while (c == -1) {
        __asm__ volatile ("rdcycle %0" : "=r"(cycles_now));
        cycles = cycles_now - cycles_begin;
        if (cycles > 12000000) {
            if (prompt)
                print(prompt);
            cycles_begin = cycles_now;
            //reg_leds = ~reg_leds;
        }
        c = reg_uart_data;
    }

    return c;
}

char getchar()
{
    return getchar_prompt(0);
}

void cmd_print_spi_state()
{
    print("SPI State:\n");

    print("  LATENCY ");
    print_dec((reg_spictrl >> 16) & 15);
    print("\n");

    print("  DDR ");
    if ((reg_spictrl & (1 << 22)) != 0)
        print("ON\n");
    else
        print("OFF\n");

    print("  QSPI ");
    if ((reg_spictrl & (1 << 21)) != 0)
        print("ON\n");
    else
        print("OFF\n");

    print("  CRM ");
    if ((reg_spictrl & (1 << 20)) != 0)
        print("ON\n");
    else
        print("OFF\n");
}

    /*
     *
     */

// Base address of peripheral blocks
#define ADDR_COEF   ((uint32_t*) 0x60000000)
#define ADDR_RESULT ((uint32_t*) 0x61000000)
#define ADDR_STAT   ((uint32_t*) 0x62000000)
#define ADDR_RESET  ((uint32_t*) 0x63000000)
#define ADDR_AUDIO  ((uint32_t*) 0x64000000)
#define ADDR_LED    ((uint32_t*) 0x03000000)

#define AUDIO_ITEMS 512
#define CHANNELS    8
#define CHAN_W      3
#define FRAMES      256
#define OFFSET_W    8

enum Opcode {
    HALT    = 0xf,
    CAPTURE = 0x1,
    MAC     = 0x8,
    MACZ    = 0x9,
    MACN    = 0xa,
    MACNZ   = 0xb,
    SAVE    = 0x2,
    NOOP    = 0x0,
};

bool verbose = false;

uint32_t opcode(uint8_t opcode, uint16_t offset, uint8_t chan, int32_t gain)
{
    if (gain < 0)
    {
        switch (opcode)
        {
            case MACZ : opcode = MACNZ; break;
            case MAC  : opcode = MACN;  break;
            default   : ASSERT(0);
        }
        gain = -gain;
    }
    const uint32_t value = gain + (chan << 16) + (offset << (16+CHAN_W)) + (opcode << (16+CHAN_W+OFFSET_W));

    if (!verbose)
        return value;

    print("code : ");
    print_hex(value, 8);
    print(" ");

    switch (opcode)
    {
        case HALT   :   print("HALT "); break;
        case CAPTURE:   print("CAPT "); break;
        case MAC    :   print("MAC  "); break;
        case MACZ   :   print("MACZ "); break;
        case MACN   :   print("MACN "); break;
        case MACNZ  :   print("MACNZ"); break;
        case SAVE   :   print("SAVE "); break;
        case NOOP   :   print("NOOP "); break;
        default     :   print("ERROR"); break;
    }

    if (opcode == CAPTURE)
    {
        print_hex(offset, 1);
        switch (offset)
        {
            case 0 : print(" next cooef"); break;
            case 1 : print(" audio in/addr"); break;
            case 2 : print(" mul in a/b"); break;
            case 3 : print(" mul out"); break;
            case 5 : print(" acc out"); break;
            case 6 : print(" out addr / audio"); break;
            case 7 : print(" trace"); break;
        }
    }
    if ((opcode == MAC) || (opcode == MACZ) || (opcode == MACN) || (opcode == MACNZ))
    {
        print("offset=");
        print_hex(offset, 2);
        print(" chan=");
        print_hex(chan, 1);
        print(" gain=");
        print_hex(gain, 4);
    }
    if (opcode == SAVE)
    {
        print(" shift=");
        print_hex(offset, 2);
        print(" addr=");
        print_hex(gain & 0xff, 2);
    }

    print("\n");

    return value;
}

    /*
     *
     */

void reset_engine()
{
    if (verbose) print("reset engine\n");

    // Reset the audio engine
    uint32_t *reset = ADDR_RESET;
    *reset = 0;

    // Wait for done
    uint32_t *status = ADDR_STAT;

    while (true)
    {
        uint32_t t = status[0];
        if (t & 0x01)
            return;

        if (verbose)
        {
            print("status ");
            print_hex(t, 8);
            print("\n");
        }
    }
}

void set_audio(uint32_t addr, uint32_t value)
{
    uint32_t *input = ADDR_AUDIO;
    input[addr] = value;

    if (!verbose)
        return;

    print("set audio ");
    print_hex(addr, 8);
    print(" ");
    print_hex(value, 8);
    print("\n");
}

void clr_audio(uint32_t value)
{
    uint32_t *input = ADDR_AUDIO;

    if (verbose) 
    {
        print("clr_audio ");
        print_hex(value, 8);
        print("\n");
    }

    bool old = verbose;
    verbose = false;
    for (int i = 0; i < AUDIO_ITEMS; i++)
    {
        set_audio(i, value);
    }
    verbose = old;
}

void test(const char *text, uint32_t *result, uint32_t expect)
{
    reset_engine();

    uint32_t t = *result;
    if (t != expect)
        verbose = 1;
 
    if (verbose)
    {
        print(text);
        print_hex(t, 8);
        print(" expected ");
        print_hex(expect, 8);
        print("\n");
    }
    ASSERT(t == expect);
    if (verbose) print("Okay\n");
}

void run(uint32_t expect)
{
    uint32_t *status = ADDR_STAT;
    test("status ", & status[1], expect);
}

void calc(uint32_t expect)
{
    uint32_t *result = ADDR_RESULT;
    test("result ", result, expect);
}

void set_control(uint32_t v)
{
    uint32_t *status = ADDR_STAT;
    *status = v;
    if (1) // verbose)
    {
        print("set control=");
        print_hex(v, 8);
        print("\n");
    }
}

uint32_t capture(int code)
{
    return opcode(CAPTURE, code, 0, 0);
}

uint32_t halt()
{
    return opcode(HALT, 0, 0, 0);
}

uint32_t noop()
{
    return opcode(NOOP, 0, 0, 0);
}

uint16_t twoc(uint16_t n)
{
    return 0xffff & ((~0xabcd) + 1);
}

    /*
     *
     */

void cmd_dave()
{
    // control_reg
    uint32_t *status = ADDR_STAT;
    set_control(1); // allow audio writes
    // Reset the audio engine
    uint32_t *reset = ADDR_RESET;
    *reset = 0;

    print("wait for 'done'\n");
    //while ((*status & 0x01))
    //    ;

    verbose = 0;
    uint32_t *coef;

    //  Test
    print("Test fetching opcode\n");
    coef = ADDR_COEF;
    *coef++ = capture(0);
    *coef++ = opcode(MACZ, 1, 0, 0x1234);
    *coef++ = halt();
    *coef++ = halt();

    run(opcode(MACZ, 1, 0, 0x1234));

//#define ALL_TESTS

#ifdef ALL_TESTS
    //  Check reading all channels
    print("Writing to audio input\n");

    // Write an audio signal to all the input RAM locations
    for (int chan = 0; chan < CHANNELS; chan++)
    {
        for (int offset = 0; offset < FRAMES; offset++)
        {
            const int idx = (chan * FRAMES) + offset;
            const int32_t audio = ~idx;
            set_audio(idx, audio);
        }
    }

    for (int chan = 0; chan < CHANNELS; chan++)
    {
        for (int offset = 0; offset < FRAMES; offset++)
        {
            const int idx = (chan * FRAMES) + offset;
            coef = ADDR_COEF;
            *coef++ = opcode(MACZ, offset, chan, 0x1234);
            *coef++ = noop();
            *coef++ = capture(1); // audio in/addr
            *coef++ = halt();
            *coef++ = halt();

            const int32_t audio = ~idx;
            const int32_t expect = (audio << 16) + idx;
            run(expect);
        }
    }
#endif

    verbose = 0;
    //  Check multiplier input
    print("Check multiplier input\n");
    clr_audio(0);
    set_audio(FRAMES+4, 0x1234);

    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 4, 1, 0x3456);
    *coef++ = opcode(NOOP, 0, 0, 0);
    *coef++ = noop();
    *coef++ = capture(2); // mul input gain/audio
    *coef++ = halt();
    *coef++ = halt();

    run(0x34561234);

    //  Check multiplier input
    print("Check multiplier input with -ve audio 2\n");
    clr_audio(0);
    set_audio(4 + (1 * FRAMES), 0x1111);
    set_audio(5 + (1 * FRAMES), 0x1234);
    set_audio(6 + (1 * FRAMES), 0xabcd);

    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 4, 1, 0x3456);
    *coef++ = opcode(MAC, 5, 1, 0x4545);
    *coef++ = noop();
    *coef++ = noop();
    *coef++ = capture(2); // mul input gain/audio
    *coef++ = halt();
    *coef++ = halt();

    run((0x4545 << 16) + 0x1234);

    //  Check multiplier output
    print("Check multiplier output\n");
    clr_audio(0);
    set_audio(4 + (1 * FRAMES), 0x1111);
    set_audio(5 + (1 * FRAMES), 0x1234);
    set_audio(6 + (1 * FRAMES), 0xabcd);

    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 4, 1, 2);
    *coef++ = opcode(MAC, 5, 1, 0x89ab);
    *coef++ = opcode(MAC, 6, 1, 0x1234);
    *coef++ = noop();
    *coef++ = capture(3); // mul output
    *coef++ = halt();
    *coef++ = halt();

    run(0x1111 * 2);

    //  Check multiplier output 2
    print("Check multiplier output 2\n");
    clr_audio(0);
    set_audio(4 + (1 * FRAMES), 0x1111);
    set_audio(5 + (1 * FRAMES), 0x1234);
    set_audio(6 + (1 * FRAMES), 0xabcd);

    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 4, 1, 0x2000);
    *coef++ = opcode(MAC, 5, 1, 0x89ab);
    *coef++ = opcode(MAC, 6, 1, 0x1234);
    *coef++ = noop();
    *coef++ = capture(3); // mul output
    *coef++ = halt();
    *coef++ = halt();

    const uint64_t m1 = 0x1111 * 0x2000;
    run(m1);

    //  Check multiplier output 3
    print("Check multiplier output 3\n");
    clr_audio(0);
    set_audio(4 + (1 * FRAMES), 0x1111);
    set_audio(5 + (1 * FRAMES), 0x1234);
    set_audio(6 + (1 * FRAMES), 0xabcd);

    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 4, 1, 0x2000);
    *coef++ = opcode(MAC, 5, 1, 0x89ab);
    *coef++ = opcode(MAC, 6, 1, 0x1234);
    *coef++ = noop();
    *coef++ = noop();
    *coef++ = capture(3); // mul output
    *coef++ = halt();
    *coef++ = halt();

    const uint64_t m2 = 0x89ab * 0x1234;
    run(m2);

    //  Check multiplier output 4
    print("Check multiplier output 4\n");
    clr_audio(0);
    set_audio(4 + (1 * FRAMES), 0x1111);
    set_audio(5 + (1 * FRAMES), 0x1234);
    set_audio(6 + (1 * FRAMES), 0xabcd); // -ve input!
    set_audio(7 + (1 * FRAMES), 0x2222);

    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 4, 1, 0x2000);
    *coef++ = opcode(MAC, 5, 1, 0x89ab);
    *coef++ = opcode(MAC, 6, 1, 0x1234);
    *coef++ = noop();
    *coef++ = noop();
    *coef++ = noop();
    *coef++ = capture(3); // mul output
    *coef++ = halt();
    *coef++ = halt();

    const uint64_t m3 = 0x1234 * twoc(0xabcd);
    run(m3);

    //  Check accumulator output
    print("Check accumulator output\n");
    clr_audio(0);
    set_audio(4 + (1 * FRAMES), 0x1111);
    set_audio(5 + (1 * FRAMES), 0x1234);
    set_audio(6 + (1 * FRAMES), 0xabcd);
    set_audio(7 + (1 * FRAMES), 0x2222);

    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 4, 1, 0x2000);
    *coef++ = opcode(MAC, 5, 1, 0x89ab);
    *coef++ = opcode(MAC, 6, 1, 0x1234);
    *coef++ = opcode(MAC, 7, 1, 0x1111);
    *coef++ = noop();
    *coef++ = capture(5); // acc output
    *coef++ = halt();
    *coef++ = halt();

    run(m1);

    //  Check accumulator output 2
    print("Check accumulator output 2\n");
    clr_audio(0);
    set_audio(4 + (1 * FRAMES), 0x1111);
    set_audio(5 + (1 * FRAMES), 0x1234);
    set_audio(6 + (1 * FRAMES), 0xabcd);
    set_audio(7 + (1 * FRAMES), 0x2222);

    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 4, 1, 0x2000);
    *coef++ = opcode(MAC, 5, 1, 0x89ab);
    *coef++ = opcode(MAC, 6, 1, 0x1234);
    *coef++ = opcode(MAC, 7, 1, 0x1111);
    *coef++ = noop();
    *coef++ = noop();
    *coef++ = capture(5); // acc output
    *coef++ = halt();
    *coef++ = halt();

    if (verbose)
    {
        print_hex(m1, 8);
        print(" + ");
        print_hex(m2, 8);
        print(" = ");
        print_hex(m1+m2, 8);
        print("\n");
    }
    run(m1 + m2);

    //  Check accumulator output 3
    print("Check accumulator output 3 (-ve audio)\n");
    clr_audio(0);
    set_audio(4 + (1 * FRAMES), 0x1111);
    set_audio(5 + (1 * FRAMES), 0x1234);
    set_audio(6 + (1 * FRAMES), 0xabcd);
    set_audio(7 + (1 * FRAMES), 0x2222);

    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 4, 1, 0x2000);
    *coef++ = opcode(MAC, 5, 1, 0x89ab);
    *coef++ = opcode(MAC, 6, 1, 0x1234);
    *coef++ = opcode(MAC, 7, 1, 0x1111);
    *coef++ = noop();
    *coef++ = noop();
    *coef++ = noop();
    *coef++ = capture(5); // acc output
    *coef++ = halt();
    *coef++ = halt();

    if (verbose)
    {
        print_hex(m1, 8);
        print(" + ");
        print_hex(m2, 8);
        print(" - ");
        print_hex(m3, 8);
        print(" = ");
        print_hex(m1+m2-m3, 8);
        print("\n");
    }
    run(m1 + m2 - m3);

    //  Check accumulator output 4
    print("Check accumulator output 4\n");
    clr_audio(0);
    set_audio(4 + (1 * FRAMES), 0x1111);
    set_audio(5 + (1 * FRAMES), 0x1234);
    set_audio(6 + (1 * FRAMES), 0xabcd);
    set_audio(7 + (1 * FRAMES), 0x2222);

    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 4, 1, 0x2000);
    *coef++ = opcode(MAC, 5, 1, 0x89ab);
    *coef++ = opcode(MAC, 6, 1, 0x1234);
    *coef++ = opcode(MAC, 7, 1, 0x1111);
    *coef++ = noop();
    *coef++ = noop();
    *coef++ = noop();
    *coef++ = noop();
    *coef++ = capture(5); // acc output
    *coef++ = halt();
    *coef++ = halt();

    const uint32_t m4 = 0x2222 * 0x1111;
    const uint32_t acc = m1 + m2 - m3 + m4;
    run(acc);

    //  Check write output
    verbose = 0;
#ifdef ALL_TESTS
    print("Check write shift/output\n");
    clr_audio(0);
    set_audio(4 + (1 * FRAMES), 0x1111);
    set_audio(5 + (1 * FRAMES), 0x1234);
    set_audio(6 + (1 * FRAMES), 0xabcd);
    set_audio(7 + (1 * FRAMES), 0x2222);

    for (int addr = 0; addr < 16; addr++)
    {
        for (int shift = 0; shift < 24; shift++)
        {
            if (verbose) 
            {
                print("Check write output : shift=");
                print_hex(shift, 2);
                print(" addr=");
                print_hex(addr, 2);
                print("\n");
            }
            coef = ADDR_COEF;
            *coef++ = opcode(MACZ, 4, 1, 0x2000);
            *coef++ = opcode(MAC, 5, 1, 0x89ab);
            *coef++ = opcode(MAC, 6, 1, 0x1234);
            *coef++ = opcode(MAC, 7, 1, 0x1111);
            *coef++ = opcode(SAVE, shift, 0, addr);
            *coef++ = noop();
            *coef++ = noop();
            *coef++ = noop();
            *coef++ = noop();
            *coef++ = capture(6); // out addr / audio
            *coef++ = halt();
            *coef++ = halt();

            uint16_t audio = acc >> shift;
            uint32_t out = (addr << 16) + audio;
            run(out);

            uint32_t *result = ADDR_RESULT;
            uint32_t v = result[addr & 0x01];
            if (verbose)
            {
                print("output ");
                print_hex(audio, 8);
                print(" got ");
                print_hex(v, 8);
                print("\n");
            }
            ASSERT(audio == v);
        }
    }
#endif

    //  Check filter performance
    print("Check filter performance\n");
    clr_audio(0);
    set_audio(0, 0x0111);
    set_audio(1, 0x0222);
    set_audio(2, 0x0444);
    set_audio(3, 0x0888);
    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, 0, 0, 1);
    *coef++ = opcode(MAC, 1, 0, 1);
    *coef++ = opcode(MAC, 2, 0, 1);
    *coef++ = opcode(MAC, 3, 0, 1);
    *coef++ = opcode(SAVE, 0, 0, 0);
    *coef++ = halt();
    *coef++ = halt();

    calc(0xfff);

    //  
    clr_audio(0x7fff);

    verbose = true;

    //  End of tests
    print("Tests run OKAY\n");
    print("==============\n");

    coef = ADDR_COEF;

//#define SLEW_TEST
//#define PULSE_TEST
#define BANDPASS

#if defined(PULSE_TEST)
    #define TESTING
    int gain = 1024;
    int op = MACZ;
    for (int i = 0; i >= 0; i += 1)
    {
        *coef++ = opcode(op, i, 0, gain);
        gain = (gain / 2) + (gain / 4) + (gain / 8) + (gain / 16);
        if (!gain)
            break;
        op = (i & 1) ? MAC : MACN;
    }
    *coef++ = opcode(SAVE, 10, 0, 0);

    *coef++ = opcode(MACZ, 0, 1, 1);
    *coef++ = opcode(MAC,  1, 1, 1);
    *coef++ = opcode(MAC,  2, 1, 1);
    *coef++ = opcode(SAVE, 0, 0, 1);
#endif

#if defined(SLEW_TEST)
    #define TESTING
    int gain = 1024;
    int op = MACZ;
    for (int i = 20; i >= 0; i += 1)
    {
        *coef++ = opcode(op, i, 0, gain);
        gain = (gain / 2) + (gain / 4) + (gain / 8) + (gain / 16);
        if (!gain)
            break;
        op = MAC;
    }
    gain = 512;
    op = MAC;
    for (int i = 40; i >= 0; i += 1)
    {
        *coef++ = opcode(op, i, 0, gain);
        gain = (gain / 2) + (gain / 4) + (gain / 8) + (gain / 16);
        if (!gain)
            break;
        op = MAC;
    }

    *coef++ = opcode(SAVE, 10, 0, 0);
    *coef++ = opcode(MACZ, 0, 1, 1);
    *coef++ = opcode(SAVE, 0, 0, 1);
#endif // SLEW_TEST

#if defined(BANDPASS)
    #define TESTING
    int offset = 0;
    coef = ADDR_COEF;
    *coef++ = opcode(MACZ, offset++, 0, 0);
    *coef++ = opcode(MAC, offset++, 0, 75);
    *coef++ = opcode(MAC, offset++, 0, 9);
    *coef++ = opcode(MAC, offset++, 0, -1);
    *coef++ = opcode(MAC, offset++, 0, -19);
    *coef++ = opcode(MAC, offset++, 0, -39);
    *coef++ = opcode(MAC, offset++, 0, -59);
    *coef++ = opcode(MAC, offset++, 0, -72);
    *coef++ = opcode(MAC, offset++, 0, -77);
    *coef++ = opcode(MAC, offset++, 0, -68);
    *coef++ = opcode(MAC, offset++, 0, -48);
    *coef++ = opcode(MAC, offset++, 0, -18);
    *coef++ = opcode(MAC, offset++, 0, 18);
    *coef++ = opcode(MAC, offset++, 0, 53);
    *coef++ = opcode(MAC, offset++, 0, 81);
    *coef++ = opcode(MAC, offset++, 0, 96);
    *coef++ = opcode(MAC, offset++, 0, 96);
    *coef++ = opcode(MAC, offset++, 0, 81);
    *coef++ = opcode(MAC, offset++, 0, 53);
    *coef++ = opcode(MAC, offset++, 0, 18);
    *coef++ = opcode(MAC, offset++, 0, -18);
    *coef++ = opcode(MAC, offset++, 0, -48);
    *coef++ = opcode(MAC, offset++, 0, -68);
    *coef++ = opcode(MAC, offset++, 0, -77);
    *coef++ = opcode(MAC, offset++, 0, -72);
    *coef++ = opcode(MAC, offset++, 0, -59);
    *coef++ = opcode(MAC, offset++, 0, -39);
    *coef++ = opcode(MAC, offset++, 0, -19);
    *coef++ = opcode(MAC, offset++, 0, -1);
    *coef++ = opcode(MAC, offset++, 0, 9);
    *coef++ = opcode(MAC, offset++, 0, 75);
    *coef++ = opcode(SAVE, 10, 0, 0);
    *coef++ = opcode(MACZ, 0, 0, 1024);
    *coef++ = opcode(SAVE, 11, 0, 1);
    *coef++ = halt();
    *coef++ = halt();
#endif // BANDPASS

#if !defined(TESTING)
    *coef++ = opcode(MACZ, 0, 0, 0x1000);
    *coef++ = opcode(SAVE, 12, 0, 0);

    *coef++ = opcode(MACZ, 0, 1, 0x1000);
    *coef++ = opcode(SAVE, 12, 0, 1);
    *coef++ = halt();
    *coef++ = halt();
#endif

    set_control(0); // stop audio writes
    reset_engine();
    print("loop ..\n");
    while (true)
    {
    }

}

// --------------------------------------------------------

void main()
{
    reg_leds = 31;
    reg_uart_clkdiv = 104;
    print("Booting..\n");

    reg_leds = 63;
    set_flash_qspi_flag();

    reg_leds = 127;
    //while (getchar_prompt("Press ENTER to continue..\n") != '\r') { /* wait */ }

    print("\n");
    print("  ____  _          ____         ____\n");
    print(" |  _ \\(_) ___ ___/ ___|  ___  / ___|\n");
    print(" | |_) | |/ __/ _ \\___ \\ / _ \\| |\n");
    print(" |  __/| | (_| (_) |__) | (_) | |___\n");
    print(" |_|   |_|\\___\\___/____/ \\___/ \\____|\n");
    print("\n");

    print("Total memory: ");
    print_dec(MEM_TOTAL / 1024);
    print(" KiB\n");
    print("\n");

    print("\n");

    cmd_print_spi_state();
    print("\n");

    reg_leds = 0;

    cmd_dave();
}
