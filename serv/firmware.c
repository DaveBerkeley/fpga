
#include <stdint.h>
#include <stdbool.h>

#define LEDS ((uint32_t*) 0x40000000)
#define UART ((uint32_t*) 0x60000000)

uint32_t v;
uint32_t i;
uint32_t ram[256/4];
uint32_t stack;
uint32_t ram_hi[256/4];

#define PV (uint32_t)(& v)

int main(void)
{
    while (true)
    {
        *UART = PV;
        *LEDS = 0;
        *UART = PV >> 8;
        *LEDS = 0;
        *UART = PV >> 16;
        *LEDS = 0;
        *UART = PV >> 24;
        *LEDS = 1;
        *UART = v;
        *LEDS = 1;
        *UART = v >> 8;

        v += 1;
    }
    return 0;
}

void another()
{
    while (true)
    {
        *UART = 'Q';
    }
}

//  FIN
