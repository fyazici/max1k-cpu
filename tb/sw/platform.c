#include <platform.h>

/*
 * CSR utils
 */
uint64_t csr_read_mcycle(void)
{
  uint32_t x, y, z;
  do
  {
    x = READ_CSR(mcycleh);
    y = READ_CSR(mcycle);
    z = READ_CSR(mcycleh);
  } while (x != z);
  return ((uint64_t)x << 32) | (uint64_t)y;
}

uint64_t csr_read_minstret(void)
{
  uint32_t x, y, z;
  do
  {
    x = READ_CSR(minstreth);
    y = READ_CSR(minstret);
    z = READ_CSR(minstreth);
  } while (x != z);
  return ((uint64_t)x << 32) | (uint64_t)y;
}

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

/* UTIL stuff */
void usleep(uint32_t us)
{
  uint64_t begin = csr_read_mcycle();
  uint64_t end = begin + us * CPU_CYCLES_PER_US;
  while (csr_read_mcycle() < end)
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
  extern char end; /* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;

  if (heap_end == 0)
  {
    heap_end = &end;
  }
  prev_heap_end = heap_end;

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