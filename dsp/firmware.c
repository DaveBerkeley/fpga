
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

#include <stdlib.h>
#include <errno.h>

#include "firmware.h"

    /*
     *  IRQ Controller
     */

#define IRQ_ENABLE 0
#define IRQ_STATE  1
#define IRQ_ACK    2
#define IRQ_SIGNAL 3
#define IRQ_SET_EN 4
#define IRQ_CLR_EN 5

inline void irq_set_enable(uint32_t d)
{
    IRQ[IRQ_SET_EN] = d;
}

inline void irq_ack(uint32_t d)
{
    IRQ[IRQ_ACK] = d;
}

inline uint32_t irq_state()
{
    return IRQ[IRQ_STATE];
}

    /*
     *  Timer
     */

#define TIMER_MTIME_LO    0
#define TIMER_MTIME_HI    1
#define TIMER_MTIMECMP_LO 2
#define TIMER_MTIMECMP_HI 3

inline void timer_set(uint64_t t)
{
    TIMER[TIMER_MTIMECMP_LO] = t & 0xffffffff;
    TIMER[TIMER_MTIMECMP_HI] = t >> 32;
}

inline uint64_t timer_get()
{
    const uint32_t lo = TIMER[TIMER_MTIME_LO];
    const uint32_t hi = TIMER[TIMER_MTIME_HI];

    return lo + (((uint64_t) hi) << 32);
}

inline uint64_t timer_get_cmp()
{
    const uint32_t lo = TIMER[TIMER_MTIMECMP_LO];
    const uint32_t hi = TIMER[TIMER_MTIMECMP_HI];

    return lo + (((uint64_t) hi) << 32);
}

    /*
     *
     */

extern "C" void irq_handler(void)__attribute__((interrupt));;

void irq_handler(void)
{
    // check for timer interrupt
    // note :- the CPU only knows about the timer irq
    // so this will not distinguish other SoC irqs.
    uint32_t cause = read_mcause();
    if ((cause & 0xff) != 0x07)
    {
        TRACE();
        return;
    }

    uint32_t irqs = irq_state();

    if (irqs != 1)
    {
        print("\r\n");
        print_num(irqs, 16, 4);
        print(" ");
        TRACE();
        while (1) ; 
    }

    if (irqs & 0x01)
    {
        // timer irq
        irq_ack(0x01); 

        static uint64_t s = 0x01000000;
    
        s += 0x00200000;
        timer_set(s);
    
        static int i = 0;
        LEDS[0] = i;
        i += 1;
    }
}

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

void print_hex(uint32_t n, uint32_t digits)
{
    print_num(n, 16, digits);
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

#if 1
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
#endif

    TIMER[2] = 0x01000000;
    TIMER[3] = 0x00000000;

    uint32_t w, v;
    print("Timer 0x"); 
    w = TIMER[0]; // mtime_lo
    v = TIMER[1]; // mtime_hi
    print_num(v, 16, 8);
    print_num(w, 16, 8);
    print("\r\n"); 
    print("Compare 0x"); 
    w = TIMER[2]; // mtime_lo
    v = TIMER[3]; // mtime_hi
    print_num(v, 16, 8);
    print_num(w, 16, 8);
    print("\r\n"); 

    irq_set_enable(0x01); // timer irq
    //irq_set_enable(0x02); // audio_ready irq

    // This instruction does not work!
    write_mie(0x08);

    write_mstatus(0x8);
    write_mtvec((uint32_t) irq_handler);
    
    print("Run audio engine\r\n");

    engine();

    while (true)
        ;
}
