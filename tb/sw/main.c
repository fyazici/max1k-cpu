#include <stdint.h>
#include <stddef.h>

void kputchar(char);
void kprint(const char *);

volatile unsigned char *uart = (volatile unsigned char *)0x12345678;
void kputchar(char c)
{
  *uart = c;
}

void kprint(const char *str)
{
  while (*str != '\0')
  {
    kputchar(*str);
    str++;
  }
}

volatile int giValue = 0;

int main(void)
{
  kprint("Hello world!\r\n");
  while (1)
  {
    // Read input from the UART
    kputchar(giValue++);
  }
}
