
#include <stdint.h>
#include <stdbool.h>

#define LEDS ((uint32_t*) 0x40000000)

uint32_t v;
uint32_t i;
uint32_t ram[256/4];
uint32_t stack;
uint32_t ram_hi[256/4];

int main(void)
{
    uint32_t x;

#define ADDR(x) ((uint32_t)((char*) & (x)))

    while (true)
    {
        *LEDS = ADDR(i);
        v += 1;
        *LEDS = ADDR(i)>>8;
        v += 1;
        *LEDS = ADDR(i)>>16;
        v += 1;
        *LEDS = ADDR(i)>>24;
        v += 1;
    }
    return 0;
}

//  FIN
