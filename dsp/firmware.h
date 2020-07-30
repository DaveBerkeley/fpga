
    /*
     *
     */

#define LEDS  ((uint32_t*) 0x40000000)
#define uart  ((uint32_t*) 0x50000000)
#define flash ((uint32_t*) 0x70000000)

void print(const char* s);
void print_num(uint32_t n, uint32_t base, uint32_t digits);
void print_hex(uint32_t n, uint32_t digits);
void print_dec(uint32_t n);

void engine();

#define TRACE() { print(__FILE__); print(" "); print_dec(__LINE__); print("\r\n"); }

//  FIN
