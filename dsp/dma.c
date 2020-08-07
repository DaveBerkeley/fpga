
#include <stdint.h>

#include "dma.h"

#define ADDR_DMA    ((uint32_t*) 0x65000000)

#define DMA_ADDR    0
#define DMA_STEP    1
#define DMA_CYCLES  2
#define DMA_BLOCKS  3
#define DMA_START   4
#define DMA_STOP    5
#define DMA_STATUS  6

uint32_t dma_get_status()
{
    return ADDR_DMA[DMA_STATUS];
}

void dma_set_addr(void *addr)
{
    ADDR_DMA[DMA_ADDR] = (uint32_t) addr;
}

void dma_set_step(uint32_t v)
{
    ADDR_DMA[DMA_STEP] = v;
}

void dma_set_cycles(uint32_t v)
{
    ADDR_DMA[DMA_CYCLES] = v;
}

void dma_set_blocks(uint32_t v)
{
    ADDR_DMA[DMA_BLOCKS] = v;
}

    /*
     *
     */

void dma_start()
{
    ADDR_DMA[DMA_START] = 1;
}

void dma_stop()
{
    ADDR_DMA[DMA_STOP] = 1;
}

//  FIN
