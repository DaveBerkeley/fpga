
#include <stdint.h>
#include <stdbool.h>

#define LEDS ((uint32_t*) 0x40000000)
#define SPI  ((uint32_t*) 0x50000000)
#define uart ((uint32_t*) 0x60000000)

uint32_t i;
uint32_t ram[256/4];
uint32_t stack;
uint32_t ram_hi[256/4];
uint32_t x = 0xdb;

#define PV(v) (uint32_t)(& v)

int main(void)
{
    uint32_t v = 0;

    while (true)
    {
        *uart = 0xda;
        *LEDS = 0;
        *LEDS = 1;
    }
    return 0;
}

void another()
{
    while (true)
    {
        *uart = 'Q';
    }
}

//  FIN
