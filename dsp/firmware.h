
    /*
     *
     */

#define LEDS  ((uint32_t*) 0x40000000)
#define uart  ((uint32_t*) 0x50000000)
#define flash ((uint32_t*) 0x70000000)
#define IRQ   ((uint32_t*) 0x80000000)
#define TIMER ((uint32_t*) 0xc0000000)

void print(const char* s);
void print_num(uint32_t n, uint32_t base, uint32_t digits);
void print_hex(uint32_t n, uint32_t digits);
void print_dec(uint32_t n);

void engine();

#define TRACE() { print(__FILE__); print(" "); print_dec(__LINE__); print("\r\n"); }

    /*
     *  CSR access functions
     */

inline uint32_t read_mie()
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mie" : "=r"(value));
    return value;
}

inline void write_mie(uint32_t value)
{
    __asm__ volatile ("csrw mie, %0" : : "r"(value));
}

inline uint32_t read_mtvec()
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mtvec" : "=r"(value));
    return value;
}

inline void write_mtvec(uint32_t value)
{
    __asm__ volatile ("csrw mtvec, %0" : : "r"(value));
}

inline uint32_t read_mstatus()
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mstatus" : "=r"(value));
    return value;
}

inline void write_mstatus(uint32_t value)
{
    __asm__ volatile ("csrw mstatus, %0" : : "r"(value));
}

inline uint32_t read_mcause()
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mcause" : "=r"(value));
    return value;
}

inline void write_mcause(uint32_t value)
{
    __asm__ volatile ("csrw mcause, %0" : : "r"(value));
}

//  FIN
