#ifndef _PLATFORM_H_
#define _PLATFORM_H_

#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/times.h>

#include <errno.h>
#undef errno
extern int errno;

#define CPU_CLOCK_PER_US (1)
#define GPIO0_BASEADDR ((void *)0x80000000)
#define UART0_BASEADDR ((void *)0xC0000000)

#define PERIPH_CLK_HZ (50000000)

struct HAL_Uart
{
  uint32_t bauddiv;
  struct
  {
    uint8_t tx_ready : 1;
    uint8_t rx_valid : 1;
    uint32_t reserved : 30;
  } status;
  uint32_t txr;
  uint32_t rxr;
};

int HAL_uart_init(volatile struct HAL_Uart *spUart, int baudrate);
void HAL_uart_putc(volatile struct HAL_Uart *spUart, char c);
char HAL_uart_getc(volatile struct HAL_Uart *spUart);

void outbyte(char);

int _close(int file);
int _execve(char *name, char **argv, char **env);
int _fork(void);
int _fstat(int file, struct stat *st);
int _getpid(void);
int _isatty(int file);
int _kill(int pid, int sig);
int _link(char *old, char *new);
int _lseek(int file, int ptr, int dir);
int _open(const char *name, int flags, int mode);
int _read(int file, char *ptr, int len);
caddr_t _sbrk(int incr);
int _stat(char *file, struct stat *st);
int _times(struct tms *buf);
int _unlink(char *name);
int _wait(int *status);
int _write(int file, char *ptr, int len);

void out32(volatile uint32_t *, uint32_t);
void out16(volatile uint16_t *, uint16_t);
void out8(volatile uint8_t *, uint8_t);
uint32_t in32(volatile uint32_t *);
uint16_t in16(volatile uint16_t *);
uint8_t in8(volatile uint8_t *);
void usleep(uint32_t);

#endif /* _PLATFORM_H_ */