#include "nocturne.h"

bool hypercall_valid(const struct frame *frame) {
  if ((frame->spsr & 15) != 5 || frame->x[0] > SVC_BAD_VECTOR) return false;
  if (frame->x[0] == SVC_PING) return true;
  for (unsigned i = 2; i < 8; ++i)
    if (frame->x[i]) return false;
  switch (frame->x[0]) {
    case SVC_DONE: case SVC_REVOKE: case SVC_TIMER: case SVC_REVOKE_READ: case SVC_PREPARE_EXEC: return frame->x[1] == 0;
    default: return true;
  }
}
