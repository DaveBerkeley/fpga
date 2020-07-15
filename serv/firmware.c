
#include <stdint.h>
#include <stdbool.h>

uint32_t *leds = ((uint32_t*) 0x4000000);

int main(void)
{
    while (true)
    {
        *leds = 1;
        *leds = 0;
    }
    return 0;
}

//  FIN
