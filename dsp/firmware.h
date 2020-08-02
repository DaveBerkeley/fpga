
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

    /*
     *  Timer
     */

#define TIMER_MTIME_LO    0
#define TIMER_MTIME_HI    1
#define TIMER_MTIMECMP_LO 2
#define TIMER_MTIMECMP_HI 3

inline void timer_set(uint64_t t)
{
    TIMER[TIMER_MTIMECMP_LO] = t & 0xffffffff;
    TIMER[TIMER_MTIMECMP_HI] = t >> 32;
}

inline uint64_t timer_get()
{
    const uint32_t lo = TIMER[TIMER_MTIME_LO];
    const uint32_t hi = TIMER[TIMER_MTIME_HI];

    return lo + (((uint64_t) hi) << 32);
}

inline uint64_t timer_get_cmp()
{
    const uint32_t lo = TIMER[TIMER_MTIMECMP_LO];
    const uint32_t hi = TIMER[TIMER_MTIMECMP_HI];

    return lo + (((uint64_t) hi) << 32);
}

    /*
     *  IRQ Controller
     */

#define IRQ_ENABLE 0
#define IRQ_STATE  1
#define IRQ_ACK    2
#define IRQ_SIGNAL 3
#define IRQ_SET_EN 4
#define IRQ_CLR_EN 5

inline void irq_set_enable(uint32_t d)
{
    IRQ[IRQ_SET_EN] = d;
}

inline void irq_ack(uint32_t d)
{
    IRQ[IRQ_ACK] = d;
}

inline uint32_t irq_state()
{
    return IRQ[IRQ_STATE];
}

//  FIN
