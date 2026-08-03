#include <stdint.h>
#include <stddef.h>

#define CPU_CLOCK_PER_US (1)
#define GPIO0_BASEADDR ((void *)0x80000000)

void out32(volatile uint32_t *, uint32_t);
uint32_t in32(volatile uint32_t *);
void usleep(uint32_t);

void out32(volatile uint32_t *p, uint32_t v)
{
  *p = v;
}

uint32_t in32(volatile uint32_t *p)
{
  return *p;
}

void usleep(uint32_t us)
{
  volatile uint32_t ctr = us * CPU_CLOCK_PER_US;
  while (ctr--)
    ;
}

int main(void)
{
  uint32_t ctr = 0;
  while (1)
  {
    usleep(500000);
    out32(GPIO0_BASEADDR, ctr++);
  }
}
