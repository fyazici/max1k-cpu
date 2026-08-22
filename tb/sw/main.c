#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <platform.h>

#include <printf/printf.h>

volatile struct HAL_Gpio *spGpio0 = GPIO0_BASEADDR;

#define ROR8(x) (((x >> 1) | (x << 7)) & 0xFF)

extern uint32_t longest_collatz_sequence(uint32_t);

void perf_report(void);

int main(void)
{
  HAL_uart_init(UART0_BASEADDR, 115200);

  printf_("BOOT\n\r");

  spGpio0->dir = 0x0; // all output
  spGpio0->odr = 0xF0E0C080;

  perf_report();
  uint32_t limit = 1000000;
  uint32_t r = longest_collatz_sequence(limit);
  perf_report();
  printf_("Longest collatz sequence seed under %d is %d\n\r", (int)limit, (int)r);

  int i = 0;

  while (1)
  {
    usleep(500000);
    // printf_("Hello World! i=%d\n\r", i++);
    spGpio0->odr = ROR8(spGpio0->odr);
    // perf_report();
  }
}

void perf_report()
{
  uint64_t mcycle = csr_read_mcycle();
  uint64_t minstret = csr_read_minstret();
  unsigned int cpi_int = mcycle / minstret;
  unsigned int cpi_10x = (10 * mcycle) / minstret;
  unsigned int cpi_frac = cpi_10x - 10 * cpi_int;
  printf_("[PERF_REPORT] => MCYCLE: %llu MINSTRET: %llu CPI: %u.%u\n\r", mcycle, minstret, cpi_int, cpi_frac);
}

void putchar_(char c)
{
  outbyte(c);
}
