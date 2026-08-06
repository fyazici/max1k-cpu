#include <platform.h>

/*
 * HAL stuff - TODO move
 */
int HAL_uart_init(volatile struct HAL_Uart *spUart, int baudrate)
{
  spUart->bauddiv = (PERIPH_CLK_HZ / baudrate) - 1;
  return 0;
}

void HAL_uart_putc(volatile struct HAL_Uart *spUart, char c)
{
  while (!(spUart->status.tx_ready))
    ;
  spUart->txr = c;
}

char HAL_uart_getc(volatile struct HAL_Uart *spUart)
{
  while (!(spUart->status.rx_valid))
    ;
  return spUart->rxr;
}

void outbyte(char c)
{
  HAL_uart_putc(UART0_BASEADDR, c);
}

/*
 * MEM stuff
 */

void out32(volatile uint32_t *p, uint32_t v)
{
  *p = v;
}
void out16(volatile uint16_t *p, uint16_t v)
{
  *p = v;
}
void out8(volatile uint8_t *p, uint8_t v)
{
  *p = v;
}
uint32_t in32(volatile uint32_t *p)
{
  return *p;
}
uint16_t in16(volatile uint16_t *p)
{
  return *p;
}
uint8_t in8(volatile uint8_t *p)
{
  return *p;
}

/* UTIL stuff */
void usleep(uint32_t us)
{
  volatile uint32_t ctr = us * CPU_CLOCK_PER_US;
  while (ctr--)
    ;
}

/*
 * NEWLIB stuff
 */
int _close(int file)
{
  return -1;
}

int _execve(char *name, char **argv, char **env)
{
  errno = ENOMEM;
  return -1;
}

int _fork(void)
{
  errno = EAGAIN;
  return -1;
}

int _fstat(int file, struct stat *st)
{
  st->st_mode = S_IFCHR;
  return 0;
}

int _getpid(void)
{
  return 1;
}

int _isatty(int file)
{
  return 1;
}

int _kill(int pid, int sig)
{
  errno = EINVAL;
  return -1;
}

int _link(char *old, char *new)
{
  errno = EMLINK;
  return -1;
}

int _lseek(int file, int ptr, int dir)
{
  return 0;
}

int _open(const char *name, int flags, int mode)
{
  return -1;
}

int _read(int file, char *ptr, int len)
{
  return 0;
}

caddr_t _sbrk(int incr)
{
  extern char _end; /* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;

  if (heap_end == 0)
  {
    heap_end = &_end;
  }
  prev_heap_end = heap_end;
  /*
  if (heap_end + incr > stack_ptr)
  {
    write(1, "Heap and stack collision\n", 25);
    abort();
  }
  */

  heap_end += incr;
  return (caddr_t)prev_heap_end;
}

int _stat(char *file, struct stat *st)
{
  st->st_mode = S_IFCHR;
  return 0;
}

int _times(struct tms *buf)
{
  return -1;
}

int _unlink(char *name)
{
  errno = ENOENT;
  return -1;
}

int _wait(int *status)
{
  errno = ECHILD;
  return -1;
}

int _write(int file, char *ptr, int len)
{
  int todo;

  for (todo = 0; todo < len; todo++)
  {
    outbyte(*ptr++);
  }
  return len;
}