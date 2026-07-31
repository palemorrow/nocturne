#include "nocturne.h"
#include <stdio.h>

int main(void) {
  printf("#define FRAME_SIZE %zu\n#define FRAME_ELR %zu\n#define FRAME_SPSR %zu\n",
         sizeof(struct frame), offsetof(struct frame, elr), offsetof(struct frame, spsr));
  for (size_t i = 0; i < 31; ++i)
    printf("#define FRAME_X%zu %zu\n", i, offsetof(struct frame, x) + i * sizeof(uint64_t));
  return 0;
}
