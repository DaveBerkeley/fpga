
    /*
     *
     */

#if !defined(__FIRMWARE_H__)
#define __FIRMWARE_H__

#define LEDS    ((uint32_t volatile*) 0x40000000)
#define flash   ((uint32_t volatile*) 0x70000000)
#define LED_IO  ((uint32_t volatile*) 0x90000000)

    /*
     *
     */

#define TRACE() { print(__FILE__); print(" "); print_dec(__LINE__); print("\r\n"); }

#endif // __FIRMWARE_H__

//  FIN
