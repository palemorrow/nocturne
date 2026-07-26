#include "routing.h"

enum destination exception_route(struct controls controls, bool masked, enum exception exception) {
  switch (exception) {
    case EX_HVC: case EX_STAGE2: return DEST_EL2;
    case EX_SVC: return DEST_EL1;
    case EX_ID: return controls.trap_id ? DEST_EL2 : DEST_DIRECT;
    case EX_IRQ:
      return controls.irq_to_el2 ? DEST_EL2 : masked ? DEST_PENDING : DEST_EL1;
  }
  return DEST_PENDING;
}
