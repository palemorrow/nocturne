#ifndef NOCTURNE_ROUTING_H
#define NOCTURNE_ROUTING_H

#include <stdbool.h>

enum exception { EX_HVC, EX_SVC, EX_STAGE2, EX_ID, EX_IRQ };
enum destination { DEST_EL1, DEST_EL2, DEST_DIRECT, DEST_PENDING };

struct controls {
  bool irq_to_el2, trap_id;
};

enum destination exception_route(struct controls controls, bool masked, enum exception exception);

#endif
