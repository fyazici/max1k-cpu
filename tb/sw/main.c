#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

#include <platform.h>

const char *msg = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed elementum nunc elit, nec eleifend metus viverra et. Cras vehicula arcu diam, ut tempor justo blandit id. Aliquam hendrerit turpis sed urna dictum rhoncus. Aenean consectetur nulla eu elit ligula.\n\r";

volatile struct HAL_Gpio *spGpio0 = GPIO0_BASEADDR;

void puts_(const char *s);

#define ROR8(x) (((x >> 1) | (x << 7)) & 0xFF)

int main(void)
{
  HAL_uart_init(UART0_BASEADDR, 115200);

  spGpio0->dir = 0x0; // all output
  spGpio0->odr = 0xF0E0C080;

  while (1)
  {
    usleep(500000);
    puts_(msg);
    spGpio0->odr = ROR8(spGpio0->odr);
  }
}

void puts_(const char *s)
{
  char c;
  while ((c = *s++))
    outbyte(c);
}