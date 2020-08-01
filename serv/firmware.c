
#include <stdint.h>
#include <stdbool.h>

#include <stdlib.h>
#include <errno.h>

#define LEDS  ((uint32_t*) 0x40000000)
#define uart  ((uint32_t*) 0x60000000)
#define flash ((uint32_t*) 0x70000000)
#define TIMER ((uint32_t*) 0xc0000000)

// Memory locations defined in the linker config.
extern "C" uint32_t _stext, _etext, _sdata, _edata, _sheap, _eheap, _sstack, _estack, _ivector;

    /*
     *
     */

inline uint32_t read_mie()
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mie" : "=r"(value));
    return value;
}

inline void write_mie(uint32_t value)
{
    __asm__ volatile ("csrw mie, %0" : : "r"(value));
}

inline uint32_t read_mtvec()
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mtvec" : "=r"(value));
    return value;
}

inline void write_mtvec(uint32_t value)
{
    __asm__ volatile ("csrw mtvec, %0" : : "r"(value));
}

inline uint32_t read_mstatus()
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mstatus" : "=r"(value));
    return value;
}

inline void write_mstatus(uint32_t value)
{
    __asm__ volatile ("csrw mstatus, %0" : : "r"(value));
}

inline uint32_t read_mcause()
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mcause" : "=r"(value));
    return value;
}

inline void write_mcause(uint32_t value)
{
    __asm__ volatile ("csrw mcause, %0" : : "r"(value));
}

    /*
     *
     */

extern "C" void irq_handler(void)__attribute__((interrupt));;

void irq_handler(void)
{
#if 0
    uint32_t hi, lo;

    lo = TIMER[2]; // mtime_lo
    hi = TIMER[3]; // mtime_hi
    TIMER[2] = lo + 0x04000000;
    TIMER[3] = hi;
#else

    // check for timer interrupt
    uint32_t cause = read_mcause();
    if ((cause & 0xff) != 0x07)
    {
        return;
    }

    static uint64_t s = 0x01000000;

    s +=  0x01000000;
    TIMER[2] = s & 0xffffffff;
    TIMER[3] = s >> 32;
    //write_mcause(0);

    static int i = 0;
    LEDS[0] = i++;
#endif
}

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

int main(void)
{
    *LEDS = 0;

#if 0
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

    uint32_t v, w;

    TIMER[2] = 0x01000000;
    TIMER[3] = 0x00000000;

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

    // This instruction does not work!
    write_mie(0x08);

    write_mstatus(0x8);
    write_mtvec((uint32_t) irq_handler);

    int j = 0;

    while (true)
    {
        w = TIMER[0]; // mtime_lo
        v = TIMER[1]; // mtime_hi
        print_num(v, 16, 8);
        print("_");
        print_num(w, 16, 8);
        
        print(" E:");
        v = read_mie();
        print_num(v, 16, 8);

        print(" S:");
        v = read_mstatus();
        print_num(v, 16, 8);

        print(" C:");
        v = read_mcause();
        print_num(v, 16, 8);

        print(" ");
        w = TIMER[2]; // mtimecmp_lo
        v = TIMER[3]; // mtimecmp_hi
        print_num(v, 16, 8);
        print("_");
        print_num(w, 16, 8);
        print(" ");
        
        // loop
        print_num(j, 10, 2);
        j += 1;
        print("\r\n"); 

        for (int i = 0; i < 1000; i++)
        {
            v |= *LEDS;            
        }
    }

    return 0;
}

//  FIN
