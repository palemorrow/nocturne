#include "nocturne.h"

static void putc(char value) {
  volatile uint32_t *uart = (void *)0x09000000;
  while (uart[0x18 / 4] & (1U << 5)) {}
  uart[0] = (uint8_t)value;
}

void serial_puts(const char *text) {
  while (*text) putc(*text++);
}

void serial_hex(uint64_t value) {
  const char digits[] = "0123456789abcdef";
  serial_puts("0x");
  for (int shift = 60; shift >= 0; shift -= 4) putc(digits[(value >> shift) & 15]);
}

_Noreturn void finish(bool success) {
  serial_puts(success ? "result pass\n" : "result fail\n");
  uint64_t block[] = {0x20026, success ? 0 : 1};
  register uint64_t operation __asm__("x0") = 0x20;
  register void *argument __asm__("x1") = block;
  __asm__ volatile("hlt #0xf000" : "+r"(operation) : "r"(argument) : "memory");
  for (;;) BARRIER("wfe");
}

void require(bool condition, const char *message) {
  if (!condition) {
    serial_puts("failure ");
    serial_puts(message);
    serial_puts("\n");
    finish(false);
  }
}
