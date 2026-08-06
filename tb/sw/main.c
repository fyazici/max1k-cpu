#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

#include <platform.h>

void puts_(const char *s);

int main(void)
{
  HAL_uart_init(UART0_BASEADDR, 115200);

  // struct HAL_Uart *spUart0 = UART0_BASEADDR;

  while (1)
  {
    usleep(500000);

    puts_("Hello World 1111\r\n");
    // spUart0->txr = 'A';
    out32(GPIO0_BASEADDR, 1);

    usleep(500000);
    puts_("Hello World 2222\r\n");
    // spUart0->txr = 'B';
    out32(GPIO0_BASEADDR, 0);
  }
}

void puts_(const char *s)
{
  char c;
  while ((c = *s++))
    outbyte(c);
}