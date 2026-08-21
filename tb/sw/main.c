#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <platform.h>

#include <printf/printf.h>

volatile struct HAL_Gpio *spGpio0 = GPIO0_BASEADDR;

#define ROR8(x) (((x >> 1) | (x << 7)) & 0xFF)

int main(void)
{
  HAL_uart_init(UART0_BASEADDR, 115200);

  spGpio0->dir = 0x0; // all output
  spGpio0->odr = 0xF0E0C080;

  // usleep((int)malloc(1));

  int i = 0;

  while (1)
  {
    usleep(500000);
    printf_("Hello World! i=%d\n\r", i++);
    spGpio0->odr = ROR8(spGpio0->odr);
  }
}

void putchar_(char c)
{
  outbyte(c);
}
