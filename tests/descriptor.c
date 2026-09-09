#include "descriptor.h"
#include <assert.h>
#include <stdio.h>

int main(void) {
  uint64_t descriptor = 0xdeadbeef;
  assert(!stage2_descriptor(0x40300000, true, true, true, &descriptor));
  assert(descriptor == 0xdeadbeef);
  assert(!stage2_descriptor(0x40300001, true, false, true, &descriptor));
  assert(!stage2_descriptor(1UL << 40, true, false, true, &descriptor));
  for (unsigned r = 0; r < 2; ++r)
    for (unsigned w = 0; w < 2; ++w)
      for (unsigned x = 0; x < 2; ++x) {
        bool valid = stage2_descriptor(0x40300000, r, w, x, &descriptor);
        if (valid) {
          assert(!w || (r && !x));
          assert(!x || r);
          assert(((descriptor >> 6) & 3) == (r | (w << 1)));
          assert(((descriptor >> 54) & 1) == !x);
        }
      }
  puts("stage-2 descriptor permissions reject writable executable pages");
}
