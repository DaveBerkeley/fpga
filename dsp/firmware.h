
    /*
     *
     */

#define LEDS  ((uint32_t*) 0x40000000)
#define flash ((uint32_t*) 0x70000000)

    /*
     *
     */

#define TRACE() { print(__FILE__); print(" "); print_dec(__LINE__); print("\r\n"); }

//  FIN
