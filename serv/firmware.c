
#include <stdint.h>
#include <stdbool.h>

#define LEDS ((uint32_t*) 0x40000000)

int main(void)
{
    while (true)
    {
        *LEDS = 1;
        *LEDS = 0;
    }
    return 0;
}

//  FIN
