
#include <stdint.h>
#include <stdbool.h>

#define LEDS  ((uint32_t*) 0x40000000)
#define uart  ((uint32_t*) 0x60000000)
#define flash ((uint32_t*) 0x70000000)

uint32_t i;
uint32_t ram[256/4];
uint32_t stack;
uint32_t ram_hi[256/4];

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
"https://github.com/olofk/serv\r\n"
;

int main(void)
{
    *LEDS = 0;

    for (char *s = banner; *s; s++)
    {
        *uart = *s;
    }

    while (true)
    {
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
