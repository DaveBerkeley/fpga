
#define DMA_STATUS_XFER_DONE  (1 << 0)
#define DMA_STATUS_BLOCK_DONE (1 << 1)

uint32_t dma_get_status();

void dma_set_addr(void *addr);
void dma_set_match(void *addr);
void dma_set_step(uint32_t v);
void dma_set_cycles(uint32_t v);
void dma_set_blocks(uint32_t v);

void dma_start(bool repeat);
void dma_stop();

//  FIN
