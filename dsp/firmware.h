
    /*
     *
     */

#if !defined(__FIRMWARE_H__)
#define __FIRMWARE_H__

#define LEDS    ((uint32_t volatile*) 0x40000000)
#define flash   ((uint32_t volatile*) 0x70000000)

#if defined(USE_SK9822)
#define LED_IO  ((uint32_t volatile*) 0x90000000)
#endif

    /*
     *
     */

#define TRACE() { print(__FILE__); print(" "); print_dec(__LINE__); print("\r\n"); }


uint32_t colour(uint8_t bright, uint8_t r, uint8_t g, uint8_t b);

#endif // __FIRMWARE_H__

//  FIN
