#include "nocturne.h"
#include <assert.h>
#include <stdio.h>

int main(void) {
  struct frame frame = { .x = { SVC_DONE }, .spsr = 5 };
  assert(hypercall_valid(&frame));
  frame.spsr = 0;
  assert(!hypercall_valid(&frame));
  frame.spsr = 5;
  frame.x[2] = 1;
  assert(!hypercall_valid(&frame));
  frame.x[2] = 0;
  frame.x[1] = 1;
  assert(!hypercall_valid(&frame));
  frame.x[0] = SVC_PREPARE_EXEC + 1;
  assert(!hypercall_valid(&frame));
  puts("hypercall mode, service, and reserved arguments checked");
}
