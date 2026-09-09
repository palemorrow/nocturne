#include "descriptor.h"

bool stage2_descriptor(uint64_t address, bool read, bool write, bool execute, uint64_t *descriptor) {
  if ((address & 4095) || address >> 32 || (write && execute) || ((write || execute) && !read))
    return false;
  *descriptor = address | 3 | (15UL << 2) | ((uint64_t)read << 6) |
    ((uint64_t)write << 7) | (3UL << 8) | (1UL << 10) | (execute ? 0 : (1UL << 54));
  return true;
}
