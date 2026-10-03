#include <platform.h>

#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>

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

void HAL_cache_set_mask(volatile struct HAL_Cache *spCache, uint32_t mask)
{
  spCache->mask = mask;
}

void HAL_cache_invalidate(volatile struct HAL_Cache *spCache)
{
  spCache->invalidate = 1;
}

void HAL_cache_clear_counters(volatile struct HAL_Cache *spCache)
{
  spCache->hit_ctr = 0;
  spCache->miss_ctr = 0;
}

uint32_t HAL_cache_get_hit_ctr(volatile struct HAL_Cache *spCache)
{
  return spCache->hit_ctr;
}

uint32_t HAL_cache_get_miss_ctr(volatile struct HAL_Cache *spCache)
{
  return spCache->miss_ctr;
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

/* pre */
#define DOOM1WAD_BASE ((void *)(0x80000000 + 2 * 1024 * 1024)) // periph base + file offset in flash 2M
#define DOOM1WAD_END ((void *)(DOOM1WAD_BASE + 4196020));      // periph base + file offset in flash 2M
char *doom1wad_ptr = DOOM1WAD_BASE;

char dbgLevel = 0;

void setDebugLevel(char lvl)
{
  dbgLevel = lvl;
}

void dbgPrintf(char lvl, char *fmt, ...)
{
  if (lvl <= dbgLevel)
  {
    va_list args;
    va_start(args, fmt);
    printf("[DBG]: ");
    vprintf(fmt, args);
    va_end(args);
    fflush(stdout);
  }
}

/*
 * NEWLIB stuff
 */
int _close(int file)
{
  int r = -1;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _close(file=%d) = %d\n", file, r);
#endif

  return r;
}

int _execve(char *name, char **argv, char **env)
{
  errno = ENOMEM;
  int r = -1;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _execve(name=%s, argv=%zu, env=%zu) = %d\n", name, (uintptr_t)argv, (uintptr_t)env, r);
#endif

  return r;
}

int _fork(void)
{
  errno = EAGAIN;
  int r = -1;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _fork*() = %d\n", r);
#endif

  return r;
}

int _fstat(int file, struct stat *st)
{
  int r = 0;
  st->st_mode = S_IFCHR;

#if SYSCALL_DBG
  dbgPrintf(7, "[PLT] _fstat(file=%d, st=%zu) = %d\n", file, (uintptr_t)st, r);
#endif

  return 0;
}

int _getpid(void)
{
  int r = 1;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _getpid() = %d\n", r);
#endif

  return r;
}

int _isatty(int file)
{
  int r = 1;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _isatty(file=%d) = %d\n", file, r);
#endif

  return r;
}

int _kill(int pid, int sig)
{
  int r = -1;
  errno = EINVAL;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _kill(pid=%d, sig=%d) = %d\n", pid, sig, r);
#endif

  return r;
}

int _link(char *old, char *new)
{
  int r = -1;
  errno = EMLINK;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _link(old=%zu, new=%zu) = %d\n", (uintptr_t)old, (uintptr_t)new, r);
#endif

  return r;
}

int _lseek(int file, int ptr, int dir)
{
  int r = -1;

  if (file == 1000)
  {
    switch (dir)
    {
    case SEEK_SET:
      doom1wad_ptr = DOOM1WAD_BASE + ptr;
      break;
    case SEEK_CUR:
      doom1wad_ptr += ptr;
      break;
    case SEEK_END:
      doom1wad_ptr = DOOM1WAD_END + ptr;
      break;
    default:
      break;
    }
    r = doom1wad_ptr - (char *)DOOM1WAD_BASE;
  }

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _lseek(file=%d, ptr=%d, dir=%d) = %d\n", file, ptr, dir, r);
#endif

  return r;
}

int _open(const char *name, int flags, int mode)
{
  int r = -1;
  if (strstr(name, "doom1.wad"))
  {
    r = 1000;
  }

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _open(name=%s, flags=%d, mode=%d) = %d\n", name, flags, mode, r);
#endif

  return r;
}

int _read(int file, char *ptr, int len)
{
  int r = 0;
  if (file == 1000)
  {
    memcpy(ptr, doom1wad_ptr, len);
    doom1wad_ptr += len;
    r = len;
  }

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _read(file=%d, ptr=%zu, len=%d) = %d\n", file, (uintptr_t)ptr, len, r);
#endif

  return r;
}

caddr_t _sbrk(int incr)
{
  extern char end; /* Defined by the linker */
  static char *heap_end;
  char *prev_heap_end;
  caddr_t r;

  if (heap_end == 0)
  {
    heap_end = &end;
  }
  prev_heap_end = heap_end;

  uint32_t sp;
  __asm__ __volatile__("mv %0, sp" : "=r"(sp));
  if (heap_end + incr > sp)
  {
    errno = ENOMEM;
    r = (caddr_t)-1;
  }
  else
  {
    heap_end += incr;
    r = (caddr_t)prev_heap_end;
  }

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _sbrk(incr=%d) = %d\n", incr, r);
#endif

  return r;
}

int _stat(char *file, struct stat *st)
{
  int r = 0;
  st->st_mode = S_IFCHR;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _stat(file=%s, st=%zu) = %d\n", file, (uintptr_t)st, r);
#endif

  return r;
}

int _times(struct tms *buf)
{
  int r = -1;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _times(buf=%zu) = %d\n", (uintptr_t)buf, r);
#endif

  return r;
}

int _unlink(char *name)
{
  int r = -1;
  errno = ENOENT;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _unlink(name=%s) = %d\n", name, r);
#endif

  return r;
}

int _wait(int *status)
{
  int r = -1;
  errno = ECHILD;

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] _wait(status=%zu) = %d\n", (uintptr_t)status, r);
#endif

  return r;
}

int _write(int file, char *ptr, int len)
{
  if ((file == STDOUT_FILENO) || (file == STDERR_FILENO))
  {
    for (int i = 0; i < len; i++)
    {
      outbyte(*ptr++);
    }
    return len;
  }
  return -1;
}

/* Needed for DOOM */
int access(const char *_Filename, int _AccessMode)
{
  int r = -1;

  if ((_AccessMode == 4 /* R_OK */) && strstr(_Filename, "doom1.wad"))
  {
    // NOTE: respond for doom1.wad
    r = 0;
  }

#ifdef SYSCALL_DBG
  dbgPrintf(7, "[PLT] access(_Filename=%s, _AccessMode=%d) = %d\n", _Filename, _AccessMode, r);
#endif

  return r;
}

int _gettimeofday(struct timeval *tv, void *tzvp)
{
  if (tv != NULL)
  {
    long usecs = csr_read_mcycle() / (PERIPH_CLK_HZ / 1000000);

    tv->tv_sec = usecs / 1000000;
    tv->tv_usec = usecs % 1000000;
  }
  return 0;
}