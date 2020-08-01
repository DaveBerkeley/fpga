
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

#include "firmware.h"

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
    print("\r\n");
    while (true) ;
}

#define ASSERT(x) assert(x)

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

bool verbose = true;

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

    print("\r\n");

    return value;
}

    /*
     *
     */

void reset_engine()
{
    if (verbose) print("reset engine\r\n");

    // Reset the audio engine
    ADDR_RESET[0] = 0;

    // Wait for done

    while (true)
    {
        uint32_t t = ADDR_STAT[0];
        if (t & 0x01)
            return;

        if (verbose)
        {
            print("status ");
            print_hex(t, 8);
            print("\r\n");
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
    print("\r\n");
}

void clr_audio(uint32_t value)
{
    if (verbose) 
    {
        print("clr_audio ");
        print_hex(value, 8);
        print("\r\n");
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
        print("\r\n");
    }
    ASSERT(t == expect);
    if (verbose) print("Okay\r\n");
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
        print("\r\n");
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

void engine()
{
    set_control(1); // allow audio writes
    // Reset the audio engine
    uint32_t *reset = ADDR_RESET;
    *reset = 0;

    print("wait for 'done'\r\n");
    while (ADDR_STAT[0] & 0x01)
        ;

    verbose = false;
    uint32_t *coef;
    int gain = 0;
    int op = 0;

    // prevent compiler warning when all tests turned off
    gain = gain;
    op = op;

#define TEST_FETCH_OPCODE
//#define TEST_AUDIO_RAM
#define TEST_MAC
#define TEST_FILTER
#define TEST_WRITE_OUTPUT

#define ANY_TEST defined(TEST_FETCH_OPCODE) | defined(TEST_MAC) | defined(TEST_FILTER) \
    | defined(TEST_AUDIO_RAM) | defined(TEST_AUDIO_RAM) | defined(SLEW_TEST) \
    | defined(PULSE_TEST) | defined(TEST_WRITE_OUTPUT)

//#define SLEW_TEST
#define BANDPASS
//#define PULSE_TEST

#ifdef TEST_FETCH_OPCODE
    //  Test
    print("Test fetching opcode\r\n");
    coef = ADDR_COEF;
    *coef++ = capture(0);
    *coef++ = opcode(MACZ, 1, 0, 0x1234);
    *coef++ = halt();
    *coef++ = halt();

    run(opcode(MACZ, 1, 0, 0x1234));
#endif

#ifdef TEST_AUDIO_RAM
    //  Check reading all channels
    print("Writing to audio input\r\n");

    int old = verbose;
    verbose = 0;
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

    print("Checking audio input\r\n");
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
    verbose = old;
#endif

#ifdef TEST_MAC
    //  Check multiplier input
    print("Check multiplier input\r\n");
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
    print("Check multiplier input with -ve audio 2\r\n");
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
    print("Check multiplier output\r\n");
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
    print("Check multiplier output 2\r\n");
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
    print("Check multiplier output 3\r\n");
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
    print("Check multiplier output 4\r\n");
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
    print("Check accumulator output\r\n");
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
    print("Check accumulator output 2\r\n");
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
        print("\r\n");
    }
    run(m1 + m2);

    //  Check accumulator output 3
    print("Check accumulator output 3 (-ve audio)\r\n");
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
        print("\r\n");
    }
    run(m1 + m2 - m3);

    //  Check accumulator output 4
    print("Check accumulator output 4\r\n");
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
#endif

    //  Check write output
#ifdef TEST_WRITE_OUTPUT
    print("Check write shift/output\r\n");
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
                print("\r\n");
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
                print("\r\n");
            }
            ASSERT(audio == v);
        }
    }
#endif

#ifdef TEST_FILTER
    //  Check filter performance
    print("Check filter performance\r\n");
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
#endif 

    coef = ADDR_COEF;

#if defined(PULSE_TEST)
    #define TESTING
    gain = 1024;
    op = MACZ;
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
    gain = 1024;
    op = MACZ;
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

#if ANY_TEST
    print("Tests run OKAY\r\n");
    print("==============\r\n");
#endif

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

    print("running ..\r\n");
}

//  FIN
