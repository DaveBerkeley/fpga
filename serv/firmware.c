
#include <stdint.h>
#include <stdbool.h>

#define LEDS  ((uint32_t*) 0x40000000)
//#define SPI   ((uint32_t*) 0x50000000)
#define uart  ((uint32_t*) 0x60000000)
#define flash ((uint32_t*) 0x70000000)

uint32_t i;
uint32_t ram[256/4];
uint32_t stack;
uint32_t ram_hi[256/4];
uint32_t x = 0xdb;

#define PV(v) (uint32_t)(& v)

int main(void)
{
    register uint32_t v;

    while (true)
    {
        *LEDS = 0;
        // request data from flash device
        flash[0] = 0x1000c0;

        // Wait until not busy
        //while (flash[1] & 0x01)
        //    ;

        // Read the data from flash
        v = flash[1];
        *uart = v;
        *LEDS = 1;
        v = flash[1];
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
