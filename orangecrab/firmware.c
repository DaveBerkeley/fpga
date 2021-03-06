
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

#include <stdlib.h>
#include <errno.h>

#include <soc.h>

#include "firmware.h"

    /*
     *  sk9822 data format
     */

uint32_t colour(uint8_t bright, uint8_t r, uint8_t g, uint8_t b)
{
    return (bright << 24) + (b << 16) + (g << 8) + r;
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

    // 0x01 is the timer irq
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

#if defined(USE_SK9822)
        const uint8_t bright = 4;
        int idx = i % 12;
        int r = (i & 0x10) ? 255 : 0;
        int g = (i & 0x20) ? 255 : 0;
        int b = (i & 0x40) ? 255 : 0;

        for (int j = 0; j < 12; j++)
        {
            if ((r + g + b) == 0)
            {
                LED_IO[j] = colour(bright, 32, 32, 32);
                continue;
            }
            
            if (j == idx)
                LED_IO[j] = colour(bright, r, g, b);
            else
                LED_IO[j] = colour(0, 0, 0, 0);
        }
#endif // USE_SK9822
    }
}

// Memory locations defined in the linker config.
extern "C" uint32_t _stext, _etext, _sdata, _edata, _sheap, _eheap, _sstack, _estack;

// banner made with : figlet "SERV Risc-V" | sed 's/\\/\\\\/g'
char banner[] = 
"\r\n"
"  ____  _____ ______     __  ____  _            __     __\r\n"
" / ___|| ____|  _ \\ \\   / / |  _ \\(_)___  ___   \\ \\   / /\r\n"
" \\___ \\|  _| | |_) \\ \\ / /  | |_) | / __|/ __|___\\ \\ / / \r\n"
"  ___) | |___|  _ < \\ V /   |  _ <| \\__ \\ (_|_____\\ V /  \r\n"
" |____/|_____|_| \\_\\ \\_/    |_| \\_\\_|___/\\___|     \\_/   \r\n"
"\r\n"
"The World's smallest RISC-V CPU. Bit-serial Architecture.\r\n"
"\r\n"
"https://github.com/olofk/serv\r\n\r\n";

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

    timer_set(0x01000000);

    irq_set_enable(0x01); // timer irq
    //irq_set_enable(0x02); // audio_ready irq

    // This write_mie() instruction does not work!
    write_mie(0x08);
    write_mstatus(0x8);
    write_mtvec((uint32_t) irq_handler);
 
    while (true) ;
}
