#include <stddef.h>

void *memset(void *destination, int value, size_t size) {
  volatile unsigned char *bytes = destination;
  for (size_t i = 0; i < size; ++i) bytes[i] = (unsigned char)value;
  return destination;
}
