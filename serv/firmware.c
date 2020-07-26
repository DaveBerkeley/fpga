
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
        *LEDS = 0;
        //*uart = PV(v);
        //*uart = PV(v) >> 8;
        //*uart = PV(v) >> 16;
        //*uart = PV(v) >> 24;

        *LEDS = 1;
        //*uart = v;
        //*uart = v >> 8;
        //*uart = x;

        //v += 1;
        //x += 1;

        SPI[1] = 0; // set read addr
        //SPI[0] = (1 << 8) + 0x4b; // read manufacturer id +add
        //SPI[0] = 0x05; // read status reg-1
        SPI[0] = (1 << 10) + 0x66; // enable reset
        *LEDS = 0;
        SPI[0] = (1 << 10) + 0x99; // reset
        *LEDS = 0;
        SPI[0] = 0x9f; // jedec id
        *LEDS = 0;

        SPI[1] = 0x00100084; // set read addr
        SPI[0] = (3 << 8) + 0x03; // read data +inc +addr
        *LEDS = 0;
        SPI[0] = (3 << 8) + 0x03; // read data +inc +addr
        *LEDS = 0;

        v = SPI[0];
        *uart = v;
        *uart = v >> 8;
        *uart = v >> 16;
        *uart = v >> 24;

        while (true)
            ;
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
