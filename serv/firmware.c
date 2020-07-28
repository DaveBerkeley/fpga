
#include <stdint.h>
#include <stdbool.h>

#define LEDS  ((uint32_t*) 0x40000000)
#define uart  ((uint32_t*) 0x60000000)
#define flash ((uint32_t*) 0x70000000)

uint32_t i;
uint32_t ram[256/4];
uint32_t stack;
uint32_t ram_hi[256/4];
uint32_t x = 0xdb;

int main(void)
{
    register uint32_t v;

    *LEDS = 0;
    // request data from flash device
    flash[0] = 0x100020;

    while (true)
    {
        // Read the data from flash
        *LEDS = 1;
        v = flash[0];
        *uart = v >> 24;
        *LEDS = 1;
        *uart = v >> 16;
        *LEDS = 1;
        *uart = v >> 8;
        *LEDS = 1;
        *uart = v;
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
