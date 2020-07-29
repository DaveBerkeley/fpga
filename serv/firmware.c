
#include <stdint.h>
#include <stdbool.h>

#define LEDS  ((uint32_t*) 0x40000000)
#define uart  ((uint32_t*) 0x60000000)
#define flash ((uint32_t*) 0x70000000)

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
"https://github.com/olofk/serv\r\n";

    /*
     *
     */

void print_num(uint32_t n, uint32_t base)
{
    if (n > base)
    {
        print_num(n / base, base);
    }

    n %= base;
    *uart = (n > 9) ? ('a' + n - 10) : ('0' + n);
}

    /*
     *
     */

void print(const char *text)
{
    for (const char *s = text; *s; s++)
    {
        *uart = *s;
    }
}

    /*
     *
     */

int main(void)
{
    uint8_t c;

    print("sp : ");
    print_num((uint32_t) & c, 16);
    print("\r\n");

    *LEDS = 0;

    print(banner);
    print("Hello World!\r\n");

    uint16_t mask = 1;

    while (true)
    {
        *LEDS = mask;
        mask <<= 1;
        if (mask > 0x20)
            mask = 1;
        uint32_t v;
        for (int i = 0; i < 1000; i++)
            v = *LEDS;
    }

    return 0;
}

//  FIN
